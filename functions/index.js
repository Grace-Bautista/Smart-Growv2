const admin = require("firebase-admin");
const functions = require("firebase-functions/v1");

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const timestamp = admin.firestore.FieldValue.serverTimestamp;

async function getUserProfile(uid) {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Caller profile was not found."
    );
  }
  return snap.data();
}

async function requireActiveCaller(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in."
    );
  }

  const profile = await getUserProfile(context.auth.uid);
  if (profile.status !== "active") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Your account is inactive."
    );
  }

  return { uid: context.auth.uid, profile };
}

async function requireAdmin(context) {
  const caller = await requireActiveCaller(context);
  if (caller.profile.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin access is required."
    );
  }
  return caller;
}

function requireString(data, field) {
  const value = data[field];
  if (typeof value !== "string" || value.trim() === "") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} is required.`
    );
  }
  return value.trim();
}

function validateEmail(email) {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid email is required."
    );
  }
}

async function getTargetUser(uid) {
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "User was not found.");
  }
  return { ref, data: snap.data() };
}

async function requireStaffTarget(uid) {
  const target = await getTargetUser(uid);
  if (target.data.role !== "staff") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Only staff accounts can be managed here."
    );
  }
  return target;
}



exports.createStaffUser = functions.https.onCall(async (data, context) => {
  const caller = await requireAdmin(context);
  const name = requireString(data, "name");
  const email = requireString(data, "email").toLowerCase();
  const password = requireString(data, "password");

  validateEmail(email);
  if (password.length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters."
    );
  }

  const userRecord = await auth.createUser({
    email,
    password,
    displayName: name,
    disabled: false,
  });

  const userRef = db.collection("users").doc(userRecord.uid);
  try {
    await userRef.set({
      uid: userRecord.uid,
      name,
      email,
      role: "staff",
      status: "active",
      createdBy: caller.uid,
      createdAt: timestamp(),
      updatedAt: timestamp(),
    });

    return { uid: userRecord.uid };
  } catch (error) {
    await auth.deleteUser(userRecord.uid).catch(() => undefined);
    throw error;
  }
});

exports.updateStaffUser = functions.https.onCall(async (data, context) => {
  const caller = await requireAdmin(context);
  const uid = requireString(data, "uid");
  const name = requireString(data, "name");
  const email = requireString(data, "email").toLowerCase();

  validateEmail(email);
  const target = await requireStaffTarget(uid);

  await auth.updateUser(uid, {
    displayName: name,
    email,
  });
  await target.ref.update({
    name,
    email,
    updatedAt: timestamp(),
  });
  return { uid };
});

exports.deactivateUser = functions.https.onCall(async (data, context) => {
  const caller = await requireAdmin(context);
  const uid = requireString(data, "uid");

  if (uid === caller.uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot deactivate your own account."
    );
  }

  const target = await requireStaffTarget(uid);
  await auth.updateUser(uid, { disabled: true });
  await target.ref.update({
    status: "inactive",
    updatedAt: timestamp(),
  });
  return { uid };
});

exports.reactivateUser = functions.https.onCall(async (data, context) => {
  const caller = await requireAdmin(context);
  const uid = requireString(data, "uid");
  const target = await requireStaffTarget(uid);

  await auth.updateUser(uid, { disabled: false });
  await target.ref.update({
    status: "active",
    updatedAt: timestamp(),
  });
  return { uid };
});

exports.deleteUser = functions.https.onCall(async (data, context) => {
  const caller = await requireAdmin(context);
  const uid = requireString(data, "uid");

  if (uid === caller.uid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "You cannot delete your own account."
    );
  }

  const target = await requireStaffTarget(uid);
  await auth.deleteUser(uid);
  await target.ref.delete();
  return { uid };
});

exports.resetStaffPassword = functions.https.onCall(async (data, context) => {
  const caller = await requireActiveCaller(context);
  const uid = requireString(data, "uid");
  const target = await getTargetUser(uid);

  if (uid !== caller.uid) {
    if (caller.profile.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You can reset only your own password."
      );
    }
    if (target.data.role !== "staff") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Admins can reset staff passwords only."
      );
    }
  }

  if (target.data.status !== "active") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Only active accounts can request password reset links."
    );
  }

  const resetLink = await auth.generatePasswordResetLink(target.data.email);
  
  return { resetLink };
});

const DEVICE_ID = "smartGrow01";
const FIVE_MINUTES_MS = 5 * 60 * 1000;

function fiveMinuteBucketId(milliseconds) {
  return new Date(Math.floor(milliseconds / FIVE_MINUTES_MS) * FIVE_MINUTES_MS)
    .toISOString().replace(/[:.]/g, "-");
}

exports.sampleSensorHistory = functions.database
  .ref("/liveData/{deviceId}")
  .onWrite(async (change, context) => {
    if (context.params.deviceId !== DEVICE_ID || !change.after.exists()) return null;
    const live = change.after.val() || {};
    const sensors = live.sensors || {};
    const status = live.sensorStatus || {};
    const names = ["environmentTemp", "humidity", "co2", "waterLevel", "humidifierTemp"];
    // Dart history records require all five valid numeric readings. Skip this
    // bucket rather than writing fabricated zeroes for unavailable telemetry.
    const usable = names.every(
      (name) =>
        Number.isFinite(sensors[name]) &&
        status[name]?.valid !== false
    );    if (!usable) return null;
    const now = Date.now();
    const id = fiveMinuteBucketId(now);
    const values = Object.fromEntries(names.map((name) => [name, sensors[name]]));
    const validity = Object.fromEntries(names.map((name) => [name, status[name]?.valid === true]));
    const ref = db.doc(`devices/${DEVICE_ID}/sensorHistory/${id}`);
    return db.runTransaction(async (transaction) => {
      if ((await transaction.get(ref)).exists) return;
      transaction.create(ref, {
        deviceId: DEVICE_ID, timestamp: timestamp(), ...values, validity,
        bootId: live.device?.bootId || "",
      });
    });
  });

function eventDocument(context, suffix, data) {
  const id = `${context.eventId}_${suffix}`.replace(/[^a-zA-Z0-9_-]/g, "_");
  return db.doc(`devices/${DEVICE_ID}/systemEvents/${id}`).set({
    deviceId: DEVICE_ID, timestamp: timestamp(), severity: "info", ...data,
  }, {merge: true});
}

exports.logConfirmedLiveEvents = functions.database
  .ref("/liveData/{deviceId}")
  .onUpdate(async (change, context) => {
    if (context.params.deviceId !== DEVICE_ID) return null;
    const before = change.before.val() || {};
    const after = change.after.val() || {};
    const writes = [];
    const bo = before.components || {}, ao = after.components || {};
    for (const component of ["baseFan", "humidifier", "loopPump", "uvLight", "ventFan"]) {
      if (typeof ao[component] === "boolean" && bo[component] !== ao[component]) {
        writes.push(eventDocument(context, component, {category:"component", component, eventType:"state_changed", previousValue:bo[component] ?? null, newValue:ao[component], source:"device", message:`${component} turned ${ao[component] ? "on" : "off"}`, bootId:after.device?.bootId || ""}));
      }
    }
    const br = bo.refillPump || {}, ar = ao.refillPump || {};
    if (["auto","on","off"].includes(ar.mode) && br.mode !== ar.mode) writes.push(eventDocument(context,"refill_mode",{category:"component",component:"refillPump.mode",eventType:"mode_changed",previousValue:br.mode ?? null,newValue:ar.mode,source:"device",message:`Refill pump mode changed to ${ar.mode}`,bootId:after.device?.bootId||""}));
    if (typeof ar.running === "boolean" && br.running !== ar.running) writes.push(eventDocument(context,"refill_running",{category:"component",component:"refillPump.running",eventType:ar.running?"refill_started":"refill_stopped",previousValue:br.running??null,newValue:ar.running,source:ar.reason?.startsWith("auto")?"automatic_refill":"device",reason:ar.reason||"",message:`Refill pump ${ar.running?"started":"stopped"}`,bootId:after.device?.bootId||""}));
    const bv=before.sensorStatus||{}, av=after.sensorStatus||{};
    for (const sensor of Object.keys(av)) if (typeof av[sensor]?.valid === "boolean" && bv[sensor]?.valid !== av[sensor].valid) writes.push(eventDocument(context,`sensor_${sensor}`,{category:"sensor",component:sensor,eventType:av[sensor].valid?"sensor_recovered":"sensor_invalid",previousValue:bv[sensor]?.valid??null,newValue:av[sensor].valid,source:"device",severity:av[sensor].valid?"info":"warning",message:`${sensor} ${av[sensor].valid?"recovered":"became invalid"}`}));
    if (typeof after.device?.online === "boolean" && before.device?.online !== after.device.online) writes.push(eventDocument(context,"online",{category:"device",eventType:after.device.online?"device_online":"device_offline",previousValue:before.device?.online??null,newValue:after.device.online,source:"device",severity:after.device.online?"info":"warning",message:`Device ${after.device.online?"online":"offline"}`,bootId:after.device?.bootId||""}));
    const bStatus = before.componentStatus || {}, aStatus = after.componentStatus || {};
    for (const component of ["baseFan", "humidifier", "loopPump", "uvLight", "ventFan"]) {
      const previous = bStatus[component]?.fault, next = aStatus[component]?.fault;
      const hadFault = typeof previous === "string" && previous.length > 0, hasFault = typeof next === "string" && next.length > 0;
      if (hadFault !== hasFault) writes.push(eventDocument(context,`fault_${component}`,{category:"fault",component,eventType:hasFault?"fault_started":"fault_cleared",previousValue:previous??null,newValue:next??null,source:"device",message:hasFault?`${component} fault started`:`${component} fault cleared`,bootId:after.device?.bootId||""}));
    }
    const previousRefillFault = br.fault, nextRefillFault = ar.fault;
    const hadRefillFault = typeof previousRefillFault === "string" && previousRefillFault.length > 0, hasRefillFault = typeof nextRefillFault === "string" && nextRefillFault.length > 0;
    if (hadRefillFault !== hasRefillFault) writes.push(eventDocument(context,"fault_refillPump",{category:"fault",component:"refillPump",eventType:hasRefillFault?"fault_started":"fault_cleared",previousValue:previousRefillFault??null,newValue:nextRefillFault??null,source:"device",message:hasRefillFault?"refillPump fault started":"refillPump fault cleared",bootId:after.device?.bootId||""}));
    return Promise.all(writes);
  });

  exports.logCommandAcknowledgement = functions.database
  .ref("/deviceCommands/{deviceId}/components/{component}")
  .onUpdate(async (change, context) => {
    if (context.params.deviceId !== DEVICE_ID) {
      return null;
    }

    const before = change.before.val() || {};
    const after = change.after.val() || {};

    // Ignore updates where command status did not change.
    if (before.status === after.status) {
      return null;
    }

    // Final terminal command states used by Smart-Grow.
    const terminalStatuses = [
      "applied",
      "rejected",
      "expired",
    ];

    if (!terminalStatuses.includes(after.status)) {
      return null;
    }

    let eventType;

    switch (after.status) {
      case "applied":
        eventType = "command_applied";
        break;

      case "rejected":
        eventType = "command_rejected";
        break;

      case "expired":
        eventType = "command_expired";
        break;

      default:
        return null;
    }

    return eventDocument(
      context,
      "ack",
      {
        category: "command",
        component: context.params.component,
        eventType,
        source: "manual_command",

        commandId: after.commandId || "",
        requestedBy: after.requestedBy || "",

        reason: after.lastError || "",

        issuedAt:
          typeof after.issuedAt === "number"
            ? admin.firestore.Timestamp.fromMillis(
                after.issuedAt
              )
            : null,

        acknowledgedAt: timestamp(),

        severity:
          after.status === "applied"
            ? "info"
            : "warning",

        message: `Command ${after.status}`,
      }
    );
  });

exports._test = {fiveMinuteBucketId};

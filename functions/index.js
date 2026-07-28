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



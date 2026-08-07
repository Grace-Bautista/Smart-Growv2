/* DEVELOPMENT/TESTING ONLY. Run manually with Application Default Credentials. */
const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const DEVICE = "smartGrow01";
const BATCH = "history-demo-v1";

async function seed() {
  const now = Date.now();
  let batch = db.batch(), count = 0;
  async function write(ref, data) { batch.set(ref, {...data, isMock:true, seedBatchId:BATCH}); if (++count % 400 === 0) { await batch.commit(); batch=db.batch(); } }
  for (let i=0;i<=31*24*4;i++) {
    const ms=now-i*15*60*1000, wave=Math.sin(i/18), id=`seed_${Math.floor(ms/300000)}`;
    await write(db.doc(`devices/${DEVICE}/sensorHistory/${id}`),{deviceId:DEVICE,timestamp:admin.firestore.Timestamp.fromMillis(ms),environmentTemp:25.5+wave*1.7,humidity:80-wave*5,co2:520+wave*60,waterLevel:Math.max(18,95-(i%240)*.32),humidifierTemp:23.2+wave,validity:{environmentTemp:true,humidity:true,co2:true,waterLevel:true,humidifierTemp:true},bootId:"seed-boot"});
  }
  const events=[
    [1,"component","state_changed","humidifier",false,true,"manual_command"],
    [2,"component","mode_changed","refillPump.mode","off","auto","manual_command"],
    [3,"component","refill_started","refillPump.running",false,true,"automatic_refill"],
    [3.003,"component","refill_stopped","refillPump.running",true,false,"automatic_refill"],
    [8,"sensor","sensor_invalid","co2",true,false,"device"],
    [8.02,"sensor","sensor_recovered","co2",false,true,"device"],
    [15,"component","refill_started","refillPump.running",false,true,"manual_command"],
    [15.004,"component","refill_stopped","refillPump.running",true,false,"manual_command"],
  ];
  for (let i=0;i<events.length;i++) { const [days,category,eventType,component,previousValue,newValue,source]=events[i]; await write(db.doc(`devices/${DEVICE}/systemEvents/seed_event_${i}`),{deviceId:DEVICE,timestamp:admin.firestore.Timestamp.fromMillis(now-days*86400000),category,eventType,component,previousValue,newValue,source,severity:eventType==="sensor_invalid"?"warning":"info",message:`Seeded ${eventType.replaceAll("_"," ")}`}); }
  await batch.commit(); console.log(`Seeded ${count} deterministic records.`);
}

async function cleanup() {
  for (const collection of ["sensorHistory","systemEvents"]) {
    while (true) { const snapshot=await db.collection(`devices/${DEVICE}/${collection}`).where("seedBatchId","==",BATCH).limit(400).get(); if(snapshot.empty) break; const batch=db.batch(); snapshot.docs.forEach(doc=>batch.delete(doc.ref)); await batch.commit(); }
  }
  console.log(`Removed only ${BATCH} records.`);
}

(process.argv.includes("--cleanup") ? cleanup() : seed()).catch(error=>{console.error(error);process.exitCode=1;});

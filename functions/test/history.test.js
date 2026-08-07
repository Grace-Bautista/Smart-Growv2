const test = require("node:test");
const assert = require("node:assert/strict");
const { _test } = require("../index");
test("five-minute bucket is stable within a bucket", () => {
  assert.equal(_test.fiveMinuteBucketId(Date.UTC(2026,0,1,10,2)), _test.fiveMinuteBucketId(Date.UTC(2026,0,1,10,4,59)));
  assert.notEqual(_test.fiveMinuteBucketId(Date.UTC(2026,0,1,10,4,59)), _test.fiveMinuteBucketId(Date.UTC(2026,0,1,10,5)));
});

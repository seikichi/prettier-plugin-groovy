module.exports = {
  // preset: 'ts-jest',
  testEnvironment: 'node',
  displayName: "test",
  setupFiles: ["<rootDir>/tests_config/run_spec.js"],
  snapshotSerializers: ["jest-snapshot-serializer-raw"],
  testRegex: "jsfmt\\.spec\\.js$",
};

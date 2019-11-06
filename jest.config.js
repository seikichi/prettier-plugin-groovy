module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  displayName: "test",
  setupFiles: ["<rootDir>/tests_config/run_spec.ts"],
  snapshotSerializers: ["jest-snapshot-serializer-raw"],
  testRegex: "jsfmt\\.spec\\.js$",
};

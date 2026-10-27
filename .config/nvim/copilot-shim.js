const Module = require("module");
const os = require("os");

// 1. Fix Android/Termux returning empty os.cpus() which crashes worker pools
const origCpus = os.cpus;
os.cpus = function () {
  const cpus = origCpus.apply(this, arguments);
  if (Array.isArray(cpus) && cpus.length > 0) return cpus;
  return [{ model: "ARM64", speed: 2000, times: { user: 0, nice: 0, sys: 0, idle: 0, irq: 0 } }];
};

// 2. Mock object for missing native file/policy watchers on Android ARM64
const mockWatcher = {
  writeSnapshot: async () => "",
  getEventsSince: async () => [],
  subscribe: async () => ({ unsubscribe: async () => {} }),
  unsubscribe: async () => {},
  createWatcher: () => ({ on: () => {}, dispose: () => {} }),
  Watcher: class {
    on() { return this; }
    close() {}
    dispose() {}
  },
};

const isNativeWatcher = (str) =>
  typeof str === "string" &&
  (str.includes("watcher.node") ||
    str.includes("vscode-policy-watcher") ||
    str.includes("@parcel/watcher") ||
    str.includes("@vscode/policy-watcher") ||
    str.includes("kerberos.node"));

// 3. Intercept Module._resolveFilename so require.resolve() never throws MODULE_NOT_FOUND
const origResolve = Module._resolveFilename;
Module._resolveFilename = function (request, parent, isMain, options) {
  if (isNativeWatcher(request)) {
    return "copilot-native-shim";
  }
  try {
    return origResolve.apply(this, arguments);
  } catch (err) {
    if (isNativeWatcher(request) || (typeof request === "string" && request.endsWith(".node"))) {
      return "copilot-native-shim";
    }
    throw err;
  }
};

// 4. Intercept Module._load to return the mock watcher
const origLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === "copilot-native-shim" || isNativeWatcher(request)) {
    return mockWatcher;
  }
  try {
    return origLoad.apply(this, arguments);
  } catch (err) {
    if (
      isNativeWatcher(request) ||
      (typeof request === "string" && request.endsWith(".node")) ||
      (err && err.message && isNativeWatcher(err.message))
    ) {
      return mockWatcher;
    }
    throw err;
  }
};

// 5. Intercept direct process.dlopen calls for bundled .node binaries
const origDlopen = process.dlopen;
process.dlopen = function (mod, filename) {
  if (isNativeWatcher(filename)) {
    mod.exports = mockWatcher;
    return;
  }
  try {
    return origDlopen.apply(this, arguments);
  } catch (err) {
    mod.exports = mockWatcher;
    return;
  }
};

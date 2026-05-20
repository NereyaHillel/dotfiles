const _Module = require('module');
const _origLoad = _Module._load;
_Module._load = function(request, parent, isMain) {
    if (request && typeof request === 'string' && request.endsWith('watcher.node')) {
        return {}; // Silently bypass the C++ requirement
    }
    return _origLoad(request, parent, isMain);
};

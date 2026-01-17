const { contextBridge } = require('electron');

// Expose API URL to renderer
contextBridge.exposeInMainWorld('config', {
    apiUrl: 'http://localhost:8000'
});

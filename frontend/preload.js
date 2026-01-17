const { contextBridge } = require('electron');

// Expose API URL to renderer (configurable via environment variable)
contextBridge.exposeInMainWorld('config', {
    apiUrl: process.env.API_URL || 'http://localhost:8000'
});

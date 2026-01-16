// TabCab Web Extension - Background Service Worker

// Listen for extension installation
browser.runtime.onInstalled.addListener((details) => {
    console.log('TabCab installed:', details);
    
    if (details.reason === 'install') {
        // Initialize storage
        browser.storage.local.set({
            associations: [],
            settings: {
                autoGroupEnabled: true,
                groupingFrequency: 'realtime',
                theme: 'auto'
            }
        });
    }
});

// Listen for tab updates
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.status === 'complete') {
        console.log('Tab updated:', tab.title);
        // Future: Send to native app for AI processing
    }
});

// Listen for tab creation
browser.tabs.onCreated.addListener((tab) => {
    console.log('Tab created:', tab.id);
    // Future: Trigger AI grouping if enabled
});

// Listen for tab removal
browser.tabs.onRemoved.addListener(async (tabId) => {
    console.log('Tab removed:', tabId);
    
    // Clean up associations
    const result = await browser.storage.local.get('associations');
    let associations = result.associations || [];
    
    // Remove tab from all associations
    associations = associations.map(association => ({
        ...association,
        tabIDs: association.tabIDs.filter(id => id !== String(tabId))
    })).filter(association => association.tabIDs.length > 0);
    
    await browser.storage.local.set({ associations });
});

// Listen for messages from popup or content scripts
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    console.log('Message received:', message);
    
    switch (message.type) {
        case 'GET_TABS':
            handleGetTabs().then(sendResponse);
            return true; // Keep channel open for async response
            
        case 'TRIGGER_AI_GROUPING':
            handleAIGrouping().then(sendResponse);
            return true;
            
        default:
            console.warn('Unknown message type:', message.type);
    }
});

async function handleGetTabs() {
    const tabs = await browser.tabs.query({ currentWindow: true });
    return {
        success: true,
        tabs: tabs.map(tab => ({
            id: String(tab.id),
            title: tab.title,
            url: tab.url,
            favIconUrl: tab.favIconUrl,
            active: tab.active
        }))
    };
}

async function handleAIGrouping() {
    // Future: Send tabs to native app for AI processing
    // For now, return placeholder
    console.log('AI grouping triggered - native app integration pending');
    
    return {
        success: true,
        message: 'AI grouping will be implemented in Phase 2B'
    };
}

// Export for native messaging (Phase 2B)
// This will be used to communicate with the native Swift app
async function sendToNativeApp(message) {
    // Future implementation:
    // const response = await browser.runtime.sendNativeMessage('com.yourorg.tabcab', message);
    // return response;
    
    console.log('Native messaging not yet implemented:', message);
    return null;
}

console.log('TabCab background service worker initialized');

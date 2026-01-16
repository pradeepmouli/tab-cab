// TabCab Web Extension - Popup UI Logic

// DOM Elements
const loadingEl = document.getElementById('loading');
const contentEl = document.getElementById('content');
const errorEl = document.getElementById('error');
const errorMessageEl = document.getElementById('error-message');
const retryBtn = document.getElementById('retry-btn');
const searchInput = document.getElementById('search-input');
const associationsContainer = document.getElementById('associations-container');
const ungroupedTabsList = document.getElementById('ungrouped-tabs-list');
const settingsBtn = document.getElementById('settings-btn');

// State
let allTabs = [];
let associations = [];
let draggedItem = null;

// Initialize
document.addEventListener('DOMContentLoaded', init);
retryBtn.addEventListener('click', init);
searchInput.addEventListener('input', handleSearch);
settingsBtn.addEventListener('click', openSettings);

async function init() {
    try {
        showLoading();
        await loadTabs();
        await loadAssociations();
        renderUI();
        showContent();
    } catch (error) {
        console.error('Initialization error:', error);
        showError(error.message);
    }
}

async function loadTabs() {
    // Query all tabs in current window
    const tabs = await browser.tabs.query({ currentWindow: true });
    allTabs = tabs.map(tab => ({
        id: String(tab.id),
        title: tab.title,
        url: tab.url,
        favIconUrl: tab.favIconUrl,
        active: tab.active
    }));
}

async function loadAssociations() {
    // Load associations from storage
    const result = await browser.storage.local.get('associations');
    associations = result.associations || [];
}

async function saveAssociations() {
    await browser.storage.local.set({ associations });
}

function renderUI() {
    renderAssociations();
    renderUngroupedTabs();
}

function renderAssociations() {
    associationsContainer.innerHTML = '';
    
    associations.forEach(association => {
        const associationTabs = allTabs.filter(tab => 
            association.tabIDs.includes(tab.id)
        );
        
        const card = createAssociationCard(association, associationTabs);
        associationsContainer.appendChild(card);
    });
}

function createAssociationCard(association, tabs) {
    const card = document.createElement('div');
    card.className = 'association-card';
    card.dataset.associationId = association.id;
    
    // Header
    const header = document.createElement('div');
    header.className = 'association-header';
    header.draggable = true;
    header.addEventListener('dragstart', (e) => handleAssociationDragStart(e, association.id));
    header.addEventListener('dragover', handleDragOver);
    header.addEventListener('drop', (e) => handleAssociationDrop(e, association.id));
    
    const title = document.createElement('div');
    title.className = 'association-title';
    
    const colorIndicator = document.createElement('div');
    colorIndicator.className = 'color-indicator';
    colorIndicator.style.backgroundColor = association.color;
    
    const titleText = document.createElement('span');
    titleText.textContent = association.name;
    
    title.appendChild(colorIndicator);
    title.appendChild(titleText);
    
    const tabCount = document.createElement('span');
    tabCount.className = 'tab-count';
    tabCount.textContent = `${tabs.length} tab${tabs.length !== 1 ? 's' : ''}`;
    
    header.appendChild(title);
    header.appendChild(tabCount);
    card.appendChild(header);
    
    // Tabs list
    const tabsList = document.createElement('div');
    tabsList.className = 'tabs-list';
    
    tabs.forEach(tab => {
        const tabItem = createTabItem(tab, association.id);
        tabsList.appendChild(tabItem);
    });
    
    card.appendChild(tabsList);
    
    return card;
}

function renderUngroupedTabs() {
    ungroupedTabsList.innerHTML = '';
    
    const associatedTabIDs = new Set(
        associations.flatMap(a => a.tabIDs)
    );
    
    const ungroupedTabs = allTabs.filter(tab => 
        !associatedTabIDs.has(tab.id)
    );
    
    ungroupedTabs.forEach(tab => {
        const tabItem = createTabItem(tab, null);
        ungroupedTabsList.appendChild(tabItem);
    });
}

function createTabItem(tab, associationID) {
    const item = document.createElement('div');
    item.className = 'tab-item';
    item.dataset.tabId = tab.id;
    item.draggable = true;
    
    item.addEventListener('dragstart', (e) => handleTabDragStart(e, tab.id, associationID));
    item.addEventListener('dragover', handleDragOver);
    item.addEventListener('drop', (e) => handleTabDrop(e, tab.id, associationID));
    item.addEventListener('click', () => activateTab(tab.id));
    
    const favicon = document.createElement('img');
    favicon.className = 'tab-favicon';
    favicon.src = tab.favIconUrl || 'icons/icon-16.png';
    favicon.alt = '';
    
    const title = document.createElement('span');
    title.className = 'tab-title';
    title.textContent = tab.title;
    
    item.appendChild(favicon);
    item.appendChild(title);
    
    return item;
}

function handleTabDragStart(e, tabID, fromAssociationID) {
    draggedItem = {
        type: 'tab',
        tabID,
        fromAssociationID
    };
    e.dataTransfer.effectAllowed = 'move';
}

function handleAssociationDragStart(e, associationID) {
    draggedItem = {
        type: 'association',
        associationID
    };
    e.dataTransfer.effectAllowed = 'move';
}

function handleDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
}

async function handleTabDrop(e, targetTabID, targetAssociationID) {
    e.preventDefault();
    e.stopPropagation();
    
    if (!draggedItem) return;
    
    if (draggedItem.type === 'tab') {
        const sourceTabID = draggedItem.tabID;
        const fromAssociationID = draggedItem.fromAssociationID;
        
        // Tab-on-tab scenario
        if (sourceTabID !== targetTabID) {
            if (!fromAssociationID && !targetAssociationID) {
                // Both ungrouped - create new association
                await createNewAssociation(sourceTabID, targetTabID);
            } else if (targetAssociationID && !fromAssociationID) {
                // Add to existing association
                await addTabToAssociation(sourceTabID, targetAssociationID);
            }
        }
    }
    
    draggedItem = null;
    await init();
}

async function handleAssociationDrop(e, targetAssociationID) {
    e.preventDefault();
    e.stopPropagation();
    
    if (!draggedItem) return;
    
    if (draggedItem.type === 'tab') {
        const sourceTabID = draggedItem.tabID;
        const fromAssociationID = draggedItem.fromAssociationID;
        
        // Add tab to association
        if (fromAssociationID !== targetAssociationID) {
            if (fromAssociationID) {
                await removeTabFromAssociation(sourceTabID, fromAssociationID);
            }
            await addTabToAssociation(sourceTabID, targetAssociationID);
        }
    } else if (draggedItem.type === 'association') {
        const sourceAssociationID = draggedItem.associationID;
        
        // Merge associations
        if (sourceAssociationID !== targetAssociationID) {
            const confirmMerge = confirm('Merge these associations?');
            if (confirmMerge) {
                await mergeAssociations(sourceAssociationID, targetAssociationID);
            }
        }
    }
    
    draggedItem = null;
    await init();
}

async function createNewAssociation(tab1ID, tab2ID) {
    const tab1 = allTabs.find(t => t.id === tab1ID);
    const tab2 = allTabs.find(t => t.id === tab2ID);
    
    const name = suggestAssociationName(tab1, tab2);
    const userProvidedName = prompt('Name for new association:', name);
    
    if (!userProvidedName) return;
    
    const newAssociation = {
        id: generateUUID(),
        name: userProvidedName,
        color: generateRandomColor(),
        tabIDs: [tab1ID, tab2ID],
        createdAt: new Date().toISOString(),
        isAIGenerated: false
    };
    
    associations.push(newAssociation);
    await saveAssociations();
}

async function addTabToAssociation(tabID, associationID) {
    const association = associations.find(a => a.id === associationID);
    if (association && !association.tabIDs.includes(tabID)) {
        association.tabIDs.push(tabID);
        await saveAssociations();
    }
}

async function removeTabFromAssociation(tabID, associationID) {
    const association = associations.find(a => a.id === associationID);
    if (association) {
        association.tabIDs = association.tabIDs.filter(id => id !== tabID);
        
        // Remove association if empty
        if (association.tabIDs.length === 0) {
            associations = associations.filter(a => a.id !== associationID);
        }
        
        await saveAssociations();
    }
}

async function mergeAssociations(sourceID, targetID) {
    const source = associations.find(a => a.id === sourceID);
    const target = associations.find(a => a.id === targetID);
    
    if (source && target) {
        // Merge tab IDs
        const mergedTabIDs = [...new Set([...target.tabIDs, ...source.tabIDs])];
        target.tabIDs = mergedTabIDs;
        
        // Remove source association
        associations = associations.filter(a => a.id !== sourceID);
        
        await saveAssociations();
    }
}

async function activateTab(tabID) {
    await browser.tabs.update(Number(tabID), { active: true });
}

function handleSearch(e) {
    const query = e.target.value.toLowerCase();
    
    // Filter tabs and associations based on search
    document.querySelectorAll('.tab-item').forEach(item => {
        const title = item.querySelector('.tab-title').textContent.toLowerCase();
        item.style.display = title.includes(query) ? 'flex' : 'none';
    });
    
    document.querySelectorAll('.association-card').forEach(card => {
        const title = card.querySelector('.association-title span').textContent.toLowerCase();
        const hasVisibleTabs = Array.from(card.querySelectorAll('.tab-item'))
            .some(item => item.style.display !== 'none');
        card.style.display = (title.includes(query) || hasVisibleTabs) ? 'block' : 'none';
    });
}

function openSettings() {
    // TODO: Open settings page
    console.log('Settings clicked');
}

function suggestAssociationName(tab1, tab2) {
    try {
        const domain1 = new URL(tab1.url).hostname.replace('www.', '');
        const domain2 = new URL(tab2.url).hostname.replace('www.', '');
        
        if (domain1 === domain2) {
            return domain1.split('.')[0].charAt(0).toUpperCase() + 
                   domain1.split('.')[0].slice(1);
        }
    } catch (e) {
        console.error('Error parsing URLs:', e);
    }
    
    return 'New Association';
}

function generateRandomColor() {
    const colors = ['#FF3B30', '#FF9500', '#FFCC00', '#34C759', '#00C7BE', '#30B0C7', '#32ADE6', '#007AFF', '#5856D6', '#AF52DE', '#FF2D55'];
    return colors[Math.floor(Math.random() * colors.length)];
}

function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

function showLoading() {
    loadingEl.classList.remove('hidden');
    contentEl.classList.add('hidden');
    errorEl.classList.add('hidden');
}

function showContent() {
    loadingEl.classList.add('hidden');
    contentEl.classList.remove('hidden');
    errorEl.classList.add('hidden');
}

function showError(message) {
    loadingEl.classList.add('hidden');
    contentEl.classList.add('hidden');
    errorEl.classList.remove('hidden');
    errorMessageEl.textContent = message;
}

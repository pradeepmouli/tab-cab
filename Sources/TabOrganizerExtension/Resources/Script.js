//
//  Script.js
//  TabOrganizerExtension
//
//  Content script injected into web pages for tab context analysis.
//  Communicates with SafariExtensionHandler via message passing.
//

(function() {
    'use strict';

    console.log('Tab Organizer content script loaded');

    // MARK: - Message Passing to Extension Handler

    /**
     * Sends a message to the Safari extension handler.
     *
     * @param {string} messageName - The message identifier
     * @param {Object} userInfo - Optional message payload
     */
    function sendMessageToExtension(messageName, userInfo = {}) {
        safari.extension.dispatchMessage(messageName, userInfo);
    }

    /**
     * Handles messages from the extension handler.
     *
     * @param {Object} event - The message event
     */
    function handleMessageFromExtension(event) {
        const messageName = event.name;
        const userInfo = event.message;

        console.log(`Received message from extension: ${messageName}`, userInfo);

        switch (messageName) {
            case 'highlightTab':
                // TODO: Phase 5 (US3) - Apply visual highlight to tab
                console.log('Highlight tab requested');
                break;

            case 'clearHighlight':
                // TODO: Phase 5 (US3) - Remove visual highlight
                console.log('Clear highlight requested');
                break;

            case 'extractContext':
                // TODO: Phase 4 (US2) - Extract page context for AI analysis
                const context = extractPageContext();
                sendMessageToExtension('contextExtracted', { context });
                break;

            default:
                console.warn(`Unknown message: ${messageName}`);
        }
    }

    // MARK: - Page Context Extraction

    /**
     * Extracts context from the current page for AI analysis.
     *
     * **Privacy (FR-029)**: Only extracts metadata - no full content transmission.
     *
     * @returns {Object} Page context metadata
     */
    function extractPageContext() {
        // Extract page metadata for AI grouping suggestions
        // FR-029: No full content transmission - only metadata

        const context = {
            title: document.title,
            url: window.location.href,
            domain: window.location.hostname,

            // Extract meta tags for better categorization
            description: getMetaContent('description'),
            keywords: getMetaContent('keywords'),

            // Extract visible headings (privacy-safe)
            headings: extractHeadings(),

            // Page type detection
            isArticle: isArticlePage(),
            isEcommerce: isEcommercePage(),
            isSocialMedia: isSocialMediaPage(),

            // Timestamp for staleness detection
            extractedAt: new Date().toISOString()
        };

        return context;
    }

    /**
     * Gets meta tag content by name.
     *
     * @param {string} name - Meta tag name
     * @returns {string} Meta content or empty string
     */
    function getMetaContent(name) {
        const meta = document.querySelector(`meta[name="${name}"]`);
        return meta ? meta.getAttribute('content') : '';
    }

    /**
     * Extracts visible headings from the page.
     *
     * @returns {Array<string>} Array of heading texts (max 5)
     */
    function extractHeadings() {
        const headings = document.querySelectorAll('h1, h2, h3');
        return Array.from(headings)
            .slice(0, 5) // Limit to 5 headings
            .map(h => h.textContent.trim())
            .filter(text => text.length > 0);
    }

    /**
     * Detects if page is an article/blog post.
     *
     * @returns {boolean} True if article page detected
     */
    function isArticlePage() {
        const articleSelectors = [
            'article',
            '[itemtype*="Article"]',
            '.post',
            '.article',
            '.blog-post'
        ];

        return articleSelectors.some(selector =>
            document.querySelector(selector) !== null
        );
    }

    /**
     * Detects if page is e-commerce/shopping.
     *
     * @returns {boolean} True if e-commerce page detected
     */
    function isEcommercePage() {
        const ecommerceIndicators = [
            '[itemtype*="Product"]',
            '.add-to-cart',
            '.price',
            '.shopping-cart',
            '.checkout'
        ];

        return ecommerceIndicators.some(selector =>
            document.querySelector(selector) !== null
        );
    }

    /**
     * Detects if page is social media.
     *
     * @returns {boolean} True if social media page detected
     */
    function isSocialMediaPage() {
        const socialDomains = [
            'twitter.com',
            'facebook.com',
            'instagram.com',
            'linkedin.com',
            'reddit.com',
            'youtube.com',
            'tiktok.com'
        ];

        return socialDomains.some(domain =>
            window.location.hostname.includes(domain)
        );
    }

    // MARK: - Visual Highlighting (US3 - Phase 5)

    /**
     * Applies visual highlight to indicate related context.
     *
     * TODO: Phase 5 (US3) - Implement highlight styling
     */
    function applyHighlight() {
        // Will be implemented in Phase 5 (US3 - Context-Aware Tab Highlighting)
        // Apply CSS class or inline styles to indicate tab is highlighted
    }

    /**
     * Removes visual highlight.
     *
     * TODO: Phase 5 (US3) - Implement highlight removal
     */
    function removeHighlight() {
        // Will be implemented in Phase 5 (US3)
        // Remove CSS class or inline styles
    }

    // MARK: - Initialization

    // Register message listener
    safari.self.addEventListener('message', handleMessageFromExtension);

    // Notify extension that content script is ready
    sendMessageToExtension('contentScriptReady', {
        url: window.location.href,
        title: document.title
    });

    // TODO: Phase 5+ - Set up mutation observers for dynamic content
    // TODO: Phase 5+ - Listen for visibility changes to track tab views

})();

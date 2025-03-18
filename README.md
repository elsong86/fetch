# Fetch Recipe App

## Summary

This iOS app displays a collection of recipes fetched from a remote API. It's built using SwiftUI and follows modern iOS development practices with Swift Concurrency (async/await).

<p align="center">
  <img src="fetch_assessment/Screenshots/results1.png" width="300" alt="Recipe List Screen" style="margin-right: 10px;"/>
  <img src="fetch_assessment/Screenshots/details1.png" width="300" alt="Recipe Detail Screen"/>
</p>

### Key Features:
- Browse a collection of recipes with images, names, and cuisine types
- View detailed recipe information with source links and YouTube videos when available
- Pull to refresh for updated content
- Custom image caching system to minimize network usage
- Graceful error handling and user feedback
- Comprehensive unit tests

## Focus Areas

### Custom Image Caching
I prioritized implementing an efficient custom image caching system that:
- Saves downloaded images to disk
- Checks cache before making network requests
- Uses efficient image loading with ImageIO/CoreGraphics
- Includes detailed logging for debugging
- Is thoroughly unit tested

### Error Handling and User Experience
I focused on making the app robust by providing:
- Informative error messages for different network conditions
- Loading states with redacted placeholders
- Empty state handling
- Graceful handling of malformed data

### Testability
I structured the code to be highly testable through:
- Protocol-based dependency injection
- Clear separation of concerns
- Mock implementations for testing network operations
- Comprehensive unit tests for critical components

## Time Spent

I spent approximately 12-15 hours on this project, with time distributed as follows:
- 3 hours: Initial setup, model design, and networking architecture
- 4 hours: Building the UI components and implementing the view models
- 3 hours: Implementing and refining the custom image caching system
- 3 hours: Writing unit tests
- 1-2 hours: Polishing UI details and refining error handling

## Trade-offs and Decisions

### Architecture Choice
I went with MVVM architecture as it works well with SwiftUI's declarative approach and makes testing easier by separating business logic from view code.

### Cache Implementation
For image caching, I chose to:
- Use disk storage instead of memory caching to preserve images across app launches
- Use URL hashing for filenames rather than implementing a more complex cache eviction policy
- Focus on robustness over advanced features like cache size limits or background cleanup

### Networking and Error Handling
I implemented a comprehensive error handling strategy with:
- Specific error messages for different failure modes
- Detailed logging for debugging
- Typed error handling rather than generic error messaging

## Weakest Part of the Project

Given more time, I would have improved:

1. **Cache management**: The current implementation doesn't have cache expiration or size limits. A production app would need a better strategy for managing cache growth over time.

2. **UI Polish**: While functional, the UI could use more refinement in terms of animations, transitions, and a more distinctive visual design.

3. **Network Retry Logic**: The app currently doesn't implement retry mechanisms for failed network requests, which would improve resilience to temporary connectivity issues.

## Additional Information

### Testing Approach
I focused on unit testing the critical components, particularly:
- Image caching functionality
- Network request handling and error cases
- ViewModel state management

The tests use mock implementations of dependencies to isolate components and test specific behaviors without external dependencies.

### Potential Enhancements
Given more time, I would consider adding:
- Search and filtering capabilities
- Favorite/bookmark functionality
- Offline mode with cached recipes
- More sophisticated UI with animations
- Cache eviction policies and size management

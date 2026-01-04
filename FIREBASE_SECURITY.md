# Firebase Security Rules

## Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Anyone can read user profiles
      allow read: if true;
      
      // Only owner can create and update their profile
      allow create: if isSignedIn() && isOwner(userId);
      allow update: if isSignedIn() && isOwner(userId);
      
      // Only owner can delete their profile
      allow delete: if isSignedIn() && isOwner(userId);
    }
    
    // Products collection
    match /products/{productId} {
      // Anyone can read products
      allow read: if true;
      
      // Only authenticated users can create products
      allow create: if isSignedIn() && 
                      request.resource.data.userId == request.auth.uid;
      
      // Only product owner can update
      allow update: if isSignedIn() && 
                      resource.data.userId == request.auth.uid;
      
      // Only product owner can delete
      allow delete: if isSignedIn() && 
                      resource.data.userId == request.auth.uid;
    }
  }
}
```

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Products images
    match /products/{userId}/{imageId} {
      // Anyone can read
      allow read: if true;
      
      // Only authenticated user can upload to their folder
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 5 * 1024 * 1024 && // 5MB max
                     request.resource.contentType.matches('image/.*');
      
      // Only owner can delete
      allow delete: if request.auth != null && 
                      request.auth.uid == userId;
    }
    
    // User profile images
    match /users/{userId}/profile.jpg {
      // Anyone can read
      allow read: if true;
      
      // Only user can upload their profile
      allow write: if request.auth != null && 
                     request.auth.uid == userId &&
                     request.resource.size < 2 * 1024 * 1024 && // 2MB max
                     request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Apply Rules

### Via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project `gimie-launch`
3. Go to Firestore Database > Rules
4. Copy and paste the Firestore rules
5. Publish

### Via Firebase CLI
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

## Firestore Indexes

Create these indexes for better query performance:

```javascript
// products collection
// Composite index: createdAt (Descending) + category (Ascending)
// Composite index: userId (Ascending) + createdAt (Descending)
// Composite index: name (Ascending) + createdAt (Descending)
```

### Create via Firebase Console
1. Firestore Database > Indexes
2. Add composite indexes as needed
3. Firebase will also suggest indexes when you run queries

## Best Practices

1. **Never expose API keys in public repositories**
2. **Always validate data on the server side**
3. **Use rate limiting for API calls**
4. **Implement proper error handling**
5. **Monitor Firebase usage and costs**
6. **Regular security audits**

## Testing Rules

Test your security rules before deploying:

```bash
# Install Firebase emulator
npm install -g firebase-tools

# Run emulator
firebase emulators:start

# Test with emulator UI
# http://localhost:4000
```

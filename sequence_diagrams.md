# Sequence Diagrams for SewaSiswa

Here are the Sequence Diagrams mapping out the interactions between the User, the Flutter Application, the Supabase Backend (Auth, Database, Storage), and External APIs (Google Maps) for the main processes in your project. You can copy this code directly into draw.io, Mermaid Live, or include it directly in your FYP markdown report.

## 1. User Registration (Student or Owner)
This diagram shows the sequence of events when a new user registers on the platform.

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter App
    participant Auth as Supabase Auth
    participant DB as Supabase DB

    User->>App: Enter Email, Password & Role
    User->>App: Click 'Register'
    App->>Auth: signUp(email, password)
    activate Auth
    Auth-->>App: Return User Auth Token (UUID)
    deactivate Auth
    
    App->>DB: insertProfile(UUID, role, details)
    activate DB
    DB-->>App: Profile Created Successfully
    deactivate DB
    
    App-->>User: Navigate to Home Screen
```

## 2. Posting a Property Listing
This diagram maps out how an Owner creates a listing, uploads an image, and fetches location data.

```mermaid
sequenceDiagram
    actor Owner
    participant App as Flutter App
    participant Maps as Google Maps API
    participant Storage as Supabase Storage
    participant DB as Supabase DB

    Owner->>App: Enter Listing Details
    Owner->>App: Select Property Photo
    Owner->>App: Pin Location on Map
    Owner->>App: Click 'Submit'
    
    App->>Storage: uploadImage(photoFile)
    activate Storage
    Storage-->>App: Return Image URL
    deactivate Storage
    
    App->>Maps: getCoordinates(Pinned Location)
    activate Maps
    Maps-->>App: Return Lat/Lng Coordinates
    deactivate Maps
    
    App->>DB: insertListing(Details, Image URL, Coordinates)
    activate DB
    DB-->>App: Listing Created Successfully
    deactivate DB
    
    App-->>Owner: Display Success Message
```

## 3. Searching & Filtering Properties
This diagram details how a student searches for properties and applies distance/price filters.

```mermaid
sequenceDiagram
    actor Student
    participant App as Flutter App
    participant Maps as Google Maps API
    participant DB as Supabase DB

    Student->>App: Input Search Query & Filters
    Student->>App: Click 'Search'
    
    opt If Distance Filter Applied
        App->>Maps: getCurrentLocation()
        activate Maps
        Maps-->>App: Return User Lat/Lng
        deactivate Maps
    end
    
    App->>DB: fetchListings(filters, locationRadius)
    activate DB
    DB-->>App: Return Filtered Listings JSON
    deactivate DB
    
    App-->>Student: Render Listings on Screen
```

## 4. In-App Messaging (Realtime)
This diagram outlines the real-time communication flow when a Student messages an Owner.

```mermaid
sequenceDiagram
    actor Student
    participant App as Flutter App
    participant DB as Supabase DB (Realtime)
    actor Owner

    Student->>App: Type message and click 'Send'
    App->>DB: insertMessage(senderID, receiverID, content)
    activate DB
    DB-->>App: Success Confirmation
    
    Note over DB,Owner: Supabase Realtime WebSocket Push
    DB-->>Owner: pushNotification(newMessage)
    deactivate DB
    Owner->>Owner: UI Updates to display new message
```

## 5. Rental Payment Submission
This diagram shows how a Tenant uploads a rent payment receipt for the Owner to review.

```mermaid
sequenceDiagram
    actor Tenant
    participant App as Flutter App
    participant Storage as Supabase Storage
    participant DB as Supabase DB
    actor Owner

    App->>DB: checkRentDueDates()
    DB-->>App: Return Rent Due Status
    App-->>Tenant: Display 'Rent Due' Reminder
    
    Tenant->>App: Upload Payment Receipt
    Tenant->>App: Click 'Submit Payment'
    
    App->>Storage: uploadReceipt(receiptFile)
    activate Storage
    Storage-->>App: Return Receipt URL
    deactivate Storage
    
    App->>DB: updatePaymentStatus(Receipt URL, 'Pending')
    activate DB
    DB-->>App: Success Confirmation
    deactivate DB
    
    App-->>Tenant: Display 'Payment Submitted'
    DB-->>Owner: notify(Tenant Submitted Payment)
```

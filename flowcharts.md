# Flowcharts for SewaSiswa

Here are the Flowcharts detailing the step-by-step logic and decision paths for the main processes in your project. You can copy this Mermaid code directly into draw.io, Mermaid Live, or include it in your FYP markdown report.

## 1. User Registration & Login Flow
This flowchart shows the logic for a user entering the app, deciding to log in or register, and authenticating with Supabase.

```mermaid
flowchart TD
    Start([Start]) --> OpenApp[Open SewaSiswa App]
    OpenApp --> HasAccount{Already have an account?}
    
    HasAccount -- Yes --> EnterCreds[Enter Email & Password]
    EnterCreds --> Authenticate[Supabase Auth Login]
    Authenticate -- Success --> Dashboard[Navigate to Dashboard]
    Authenticate -- Fail --> ShowError1[Show Error Message]
    ShowError1 --> EnterCreds
    
    HasAccount -- No --> Register[Select Register]
    Register --> EnterDetails[Enter Details, Password & Select Role]
    EnterDetails --> Verify[Supabase Auth Sign Up]
    Verify -- Success --> CreateProfile[Create Profile in Database]
    Verify -- Fail --> ShowError2[Show Error Message]
    ShowError2 --> EnterDetails
    CreateProfile --> Dashboard
    
    Dashboard --> End([End])
```

## 2. Student Searching & Applying for a Property
This flowchart maps how a student searches for properties, applies filters (like distance or price), and sends an application request.

```mermaid
flowchart TD
    Start([Start]) --> Dashboard[Student Dashboard]
    Dashboard --> Search[Enter Search Query & Filters]
    Search --> FilterDB[Fetch Listings from Database]
    FilterDB --> MatchFound{Match Found?}
    
    MatchFound -- No --> ChangeFilters[Adjust Filters / Clear Search]
    ChangeFilters --> Search
    
    MatchFound -- Yes --> ViewListings[View List of Properties]
    ViewListings --> SelectListing[Click on a Listing]
    SelectListing --> ViewDetails[View Details, Map & Owner Info]
    
    ViewDetails --> DecideApply{Apply for House?}
    DecideApply -- No --> ViewListings
    DecideApply -- Yes --> ClickApply[Click 'Request' or 'Apply']
    
    ClickApply --> CheckExisting{Already a Tenant Elsewhere?}
    CheckExisting -- Yes --> ShowError[Show Error: Cannot Apply]
    ShowError --> ViewDetails
    
    CheckExisting -- No --> DBUpdate[Insert Application into Database as 'Pending']
    DBUpdate --> NotifyOwner[Send Notification to Owner]
    NotifyOwner --> Wait[Wait for Owner Approval]
    
    Wait --> End([End])
```

## 3. Owner Creating a Property Listing
This flowchart explains the process an Owner goes through to publish a new house or room for rent.

```mermaid
flowchart TD
    Start([Start]) --> Dashboard[Owner Dashboard]
    Dashboard --> ClickAdd[Click 'Add Listing']
    ClickAdd --> EnterDetails[Enter Title, Price, Description, Rules]
    EnterDetails --> UploadPhotos[Upload Property Photos]
    UploadPhotos --> PinLocation[Pin Property Location on Map]
    PinLocation --> Submit[Click 'Submit']
    
    Submit --> Storage[Upload Photos to Supabase Storage]
    Storage --> GetCoordinates[Get Lat/Lng from Google Maps API]
    GetCoordinates --> DB[Save Listing & Coordinates to Database]
    
    DB --> Success[Show Success Message]
    Success --> Redirect[Redirect to My Listings Page]
    Redirect --> End([End])
```

## 4. Tenant Submitting Rent Payment
This flowchart shows the flow when a Tenant needs to submit their monthly rent payment proof to the Owner.

```mermaid
flowchart TD
    Start([Start]) --> Notif[Receive 'Rent Due' Notification]
    Notif --> OpenApp[Open Application]
    OpenApp --> NavigateRentals[Go to My Rentals / Payment Section]
    NavigateRentals --> ViewDue[View Pending Rent Amount]
    
    ViewDue --> MakePayment[Make Payment via Online Banking/Transfer]
    MakePayment --> UploadReceipt[Upload Receipt Image]
    UploadReceipt --> SubmitPayment[Click 'Submit Payment']
    
    SubmitPayment --> Storage[Save Receipt to Supabase Storage]
    Storage --> UpdateDB[Update Payment Status to 'Pending Review' in Database]
    UpdateDB --> OwnerReview[Send Notification to Owner]
    
    OwnerReview --> Wait[Wait for Owner to Approve/Reject]
    Wait --> End([End])
```

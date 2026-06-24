# Activity Diagrams for SewaSiswa

Here are the activity diagrams for all the major processes in your application. You can use these logical flows to draw your diagrams in draw.io or use them directly in your documentation.

## 1. User Authentication (Registration & Login)
This process covers how a user creates a new account (as a Student or Owner) and how they log in.

```mermaid
flowchart TD
    Start([Start]) --> OpenApp[Open Application]
    OpenApp --> Choice{Has Account?}
    
    Choice -- No --> ClickRegister[Click 'Register']
    ClickRegister --> SelectRole[Select Role: Student or Owner]
    SelectRole --> FillReg[Fill Registration Form]
    FillReg --> SubmitReg[Submit Form]
    SubmitReg --> ValidateReg{Valid Data?}
    ValidateReg -- No --> ErrorReg[Show Error] --> FillReg
    ValidateReg -- Yes --> SaveUser[Save User to Supabase Auth] --> SuccessReg[Show Success] --> Home
    
    Choice -- Yes --> ClickLogin[Click 'Login']
    ClickLogin --> FillLogin[Enter Email & Password]
    FillLogin --> SubmitLogin[Submit Login]
    SubmitLogin --> ValidateLogin{Valid Credentials?}
    ValidateLogin -- No --> ErrorLogin[Show Error] --> FillLogin
    ValidateLogin -- Yes --> Home[Redirect to Home Screen]
    
    Home --> End([End])
    
    classDef action fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px;
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef startend fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    class OpenApp,ClickRegister,SelectRole,FillReg,SubmitReg,ErrorReg,SaveUser,SuccessReg,ClickLogin,FillLogin,SubmitLogin,ErrorLogin,Home action;
    class Choice,ValidateReg,ValidateLogin decision;
    class Start,End startend;
```

## 2. Searching & Filtering Properties
This process illustrates how a student searches for properties, applies filters (like distance radius), and views the listing details.

```mermaid
flowchart TD
    Start([Start]) --> NavHome[Navigate to Home Screen]
    NavHome --> LoadListings[System Loads All Active Listings]
    LoadListings --> Choice{Use Filters?}
    
    Choice -- No --> Browse[Browse Listings]
    Choice -- Yes --> ClickFilter[Click 'Filter' Icon]
    ClickFilter --> InputFilter[Enter Criteria\nDistance, Price, etc.]
    InputFilter --> ApplyFilter[Apply Filters]
    ApplyFilter --> QueryDB[System Queries Database]
    QueryDB --> UpdateList[Update Listings Display]
    UpdateList --> Browse
    
    Browse --> ClickListing[Click a Specific Listing]
    ClickListing --> ViewDetails[View Property Details & Map]
    ViewDetails --> End([End])

    classDef action fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px;
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef startend fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    class NavHome,LoadListings,Browse,ClickFilter,InputFilter,ApplyFilter,QueryDB,UpdateList,ClickListing,ViewDetails action;
    class Choice decision;
    class Start,End startend;
```

## 3. Posting a Housemate Request
This process shows how a student creates a post looking for a housemate.

```mermaid
flowchart TD
    Start([Start]) --> NavHousemate[Navigate to Housemate Screen]
    NavHousemate --> ClickAdd[Click 'Add Post' Button]
    ClickAdd --> DisplayForm[System Displays Post Form]
    DisplayForm --> EnterDetails[Enter Details\nBudget, Preferences, Description]
    EnterDetails --> Submit[Click 'Submit']
    Submit --> Validate{Inputs Valid?}
    
    Validate -- No --> ShowError[Show Error Message] --> EnterDetails
    Validate -- Yes --> SavePost[Save Post to Database]
    SavePost --> Success[Show Success Message]
    Success --> UpdateFeed[Update Housemate Feed]
    UpdateFeed --> End([End])

    classDef action fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px;
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef startend fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    class NavHousemate,ClickAdd,DisplayForm,EnterDetails,Submit,ShowError,SavePost,Success,UpdateFeed action;
    class Validate decision;
    class Start,End startend;
```

## 4. In-App Messaging
This process outlines how a user initiates a chat and sends a message to an owner or another student.

```mermaid
flowchart TD
    Start([Start]) --> OpenProfile[Open User/Listing Profile]
    OpenProfile --> ClickChat[Click 'Chat' Button]
    ClickChat --> OpenChat[System Opens Chat Room]
    OpenChat --> TypeMsg[Type Message]
    TypeMsg --> SendMsg[Click 'Send']
    SendMsg --> SaveMsg[Save Message to Database]
    SaveMsg --> Realtime[Push Real-time Notification via Supabase]
    Realtime --> DisplayMsg[Update Chat UI]
    DisplayMsg --> End([End])

    classDef action fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px;
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef startend fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    class OpenProfile,ClickChat,OpenChat,TypeMsg,SendMsg,SaveMsg,Realtime,DisplayMsg action;
    class Start,End startend;
```

## 5. Rental Payment Management
This process defines the flow for a tenant being reminded to pay rent and submitting their payment proof.

```mermaid
flowchart TD
    Start([Start]) --> NavPayment[Navigate to Payment Tracker]
    NavPayment --> ViewRentals[View Active Rentals]
    ViewRentals --> CheckDue{Rent Due?}
    
    CheckDue -- Yes --> Notify[System Sends Automated Reminder]
    CheckDue -- No --> Wait[Wait for Due Date]
    Wait --> End
    
    Notify --> ClickPay[Tenant Clicks 'Pay Now']
    ClickPay --> UploadProof[Upload Payment Proof Receipt]
    UploadProof --> SubmitPayment[Submit Payment]
    SubmitPayment --> UpdateStatus[Update Payment Status to 'Pending Review']
    UpdateStatus --> NotifyOwner[Notify Owner of Payment Submission]
    NotifyOwner --> End([End])

    classDef action fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px;
    classDef decision fill:#fff3e0,stroke:#ff9800,stroke-width:2px;
    classDef startend fill:#e8f5e9,stroke:#4caf50,stroke-width:2px;
    class NavPayment,ViewRentals,Notify,Wait,ClickPay,UploadProof,SubmitPayment,UpdateStatus,NotifyOwner action;
    class CheckDue decision;
    class Start,End startend;
```

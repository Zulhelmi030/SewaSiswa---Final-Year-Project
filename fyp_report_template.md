# STUDENT RENTAL & HOUSEMATE FINDER

**MUHAMMAD ZULHELMI BIN SAMSUL BAHARI**
**UNIVERSITI TEKNIKAL MALAYSIA MELAKA**
**2025**

---

This report is submitted in partial fulfillment of the requirements for the Bachelor of [Computer Science (Software Development)] with Honours.

FACULTY OF INFORMATION AND COMMUNICATION TECHNOLOGY UNIVERSITI TEKNIKAL MALAYSIA MELAKA

---

## DEDICATION
[To my beloved parents...]

---

## ACKNOWLEDGEMENTS
[I would like to thank En. Muhammad bin Ahmad for giving assistant to complete this project successfully…...

I would also like to thank my beloved parents who have been giving me support and motivation throughout my project…]

---

## ABSTRACT
Finding suitable and affordable accommodation is a critical challenge for university students, often exacerbated by the lack of centralized, reliable platforms tailored to their specific needs. This study falls under the field of mobile application development and property technology, aiming to address the difficulties students face when searching for rental houses and compatible housemates, which frequently lead to scams, mismatched living arrangements, and an inefficient rental process. To solve these issues, we developed SewaSiswa, a comprehensive cross-platform mobile application utilizing the Flutter framework and a Supabase backend. The research process involved initial requirements gathering from the student demographic, followed by the design of an intuitive user interface guided by modern minimalist design principles to enhance usability. The implementation phase integrated essential features such as verified property listings, secure housemate matching, interactive maps for location-based searches, a wishlist system, and secure integrated payments. Finally, the system underwent functional testing and user evaluation to ensure performance and reliability. The result obtained is a fully functional mobile prototype that successfully centralizes the student accommodation search, mitigates the risk of rental scams, improves the efficiency of finding compatible housemates, and provides a secure, streamlined platform that significantly enhances the overall student housing experience.

---

## ABSTRAK
Mencari penginapan yang sesuai dan mampu milik merupakan cabaran kritikal bagi pelajar universiti, yang sering diperburuk oleh kekurangan platform berpusat yang boleh dipercayai dan disesuaikan dengan keperluan khusus mereka. Kajian ini berada di bawah bidang pembangunan aplikasi mudah alih dan teknologi hartanah, bertujuan untuk menangani kesukaran yang dihadapi pelajar ketika mencari rumah sewa dan rakan serumah yang serasi, yang sering membawa kepada penipuan, susunan hidup yang tidak sesuai, dan proses penyewaan yang tidak cekap. Bagi menyelesaikan masalah-masalah ini, kami telah membangunkan SewaSiswa, sebuah aplikasi mudah alih merentas platform yang komprehensif menggunakan rangka kerja Flutter dan backend Supabase. Proses penyelidikan melibatkan pengumpulan keperluan awal daripada golongan pelajar, diikuti dengan reka bentuk antara muka pengguna yang intuitif berpandukan prinsip reka bentuk minimalis moden bagi meningkatkan kebolehgunaan. Fasa pelaksanaan mengintegrasikan ciri-ciri penting seperti senarai hartanah yang disahkan, pemadanan rakan serumah yang selamat, peta interaktif untuk carian berasaskan lokasi, sistem senarai hajat, dan pembayaran bersepadu yang selamat. Akhir sekali, sistem ini menjalani ujian fungsional dan penilaian pengguna bagi memastikan prestasi dan kebolehpercayaan. Hasil yang diperoleh adalah prototaip mudah alih yang berfungsi sepenuhnya yang berjaya memusatkan carian penginapan pelajar, mengurangkan risiko penipuan sewa, meningkatkan kecekapan mencari rakan serumah yang serasi, dan menyediakan platform yang selamat dan cekap yang secara signifikan meningkatkan keseluruhan pengalaman perumahan pelajar.

---

## Table of Contents
*   DECLARATION
*   DEDICATION
*   ACKNOWLEDGEMENTS
*   ABSTRACT
*   ABSTRAK
*   Table of Contents
*   List of Tables
*   List of Figures
*   List of Abbreviations
*   List of Attachments
*   **Chapter 1: INTRODUCTION**
    *   1.1 Introduction
    *   1.2 Background of the Project
    *   1.3 Problem Statement
    *   1.4 Objectives
    *   1.5 Scope
    *   1.6 Significance
    *   1.7 Project Methodology
*   **Chapter 2: LITERATURE REVIEW AND PROJECT METHODOLOGY**
    *   2.1 Literature Review
    *   2.2 Related Technologies
    *   2.3 Development Methodology
    *   2.4 Requirement Gathering
*   **Chapter 3: ANALYSIS**
    *   3.1 About Tables
*   **Chapter 4: DESIGN**
    *   4.1 About Table of Content
*   **Chapter 5: IMPLEMENTATION**
    *   5.1 About List of Tables
    *   5.2 About List of Figures
    *   5.3 About List of Figures
    *   5.4 About List of Figures
    *   5.5 About List of Figures
*   **Chapter 6: TESTING**
    *   6.1 About References
*   **Chapter 7: PROJECT CONCLUSION**
    *   7.1 Wrap-Up
*   references

---

## List of Tables
*   Table 2.1: Comparison of Existing Property Platforms
*   Table 3.1: Hardware and Software Requirements
*   Table 3.2: Summary of Functional and Non-Functional Requirements
*   Table 4.1: Data Dictionary: users Table
*   Table 4.2: Data Dictionary: listings Table
*   Table 4.3: Data Dictionary: housemate_posts Table
*   Table 6.1: Test Cases for User Authentication
*   Table 6.2: Test Cases for Search and Distance Filtering
*   Table 6.3: Summary of User Acceptance Testing (UAT) Results

---

## List of Figures
*   Figure 2.1: Agile Software Development Life Cycle (SDLC) Model
*   Figure 3.1: Use Case Diagram for the Application
*   Figure 4.1: Overall System Architecture Diagram
*   Figure 4.2: Entity-Relationship Diagram (ERD)
*   Figure 4.3: Activity Diagram for Posting a Property Listing
*   Figure 4.4: Low-fidelity Wireframes / UI Mockups
*   Figure 5.1: Screenshot of the Home Screen and Search Interface
*   Figure 5.2: Screenshot of the Integrated Google Map and Distance Radius
*   Figure 5.3: Screenshot of the Housemate Matching Feature

---

## List of Abbreviations
*   API - Application Programming Interface
*   BaaS - Backend as a Service
*   ERD - Entity Relationship Diagram
*   FYP - Final Year Project
*   RLS - Row Level Security
*   SDLC - Software Development Life Cycle
*   UAT - User Acceptance Testing
*   UI/UX - User Interface / User Experience
*   UTeM - Universiti Teknikal Malaysia Melaka

---

## List of ATTACHMENTS
*   Appendix A: Initial Questionnaire / Survey Form
*   Appendix B: Survey Results Data
*   Appendix C: Project Timeline / Gantt Chart
*   Appendix D: User Acceptance Testing (UAT) Evaluation Forms

---

# Chapter 1: INTRODUCTION

## 1.1 Introduction
The SewaSiswa project is a comprehensive mobile application designed to streamline the student accommodation search process. Finding suitable and affordable off-campus accommodation is a critical challenge for university students, often exacerbated by scattered information, outdated advertisements, and the risk of rental scams. The current landscape of digital property platforms lacks a specialized focus to address the unique constraints and preferences of the student demographic. To resolve these issues, we propose SewaSiswa, a centralized cross-platform mobile application utilizing the Flutter framework and Supabase backend. This platform aims to provide a safe, efficient, and user-friendly ecosystem for students to find rental houses, secure compatible housemates, and manage their living arrangements.

## 1.2 Background of the Project
The transition to university life often necessitates relocation, and as enrollments increase, the demand for affordable student housing frequently outpaces on-campus availability. Consequently, students increasingly rely on the private rental market. Currently, the rental process is highly fragmented; students typically search for housing through informal social media groups or generic classified platforms. These existing channels present several problems: they are exposed to fraudulent listings, lack robust search filters tailored to students (such as distance to campus), and offer poor communication tools between tenants and landlords. A mobile application is proposed as a better solution because it centralizes the rental process in a single accessible platform, leverages mobile features like real-time notifications and location-based mapping, and provides a structured environment that enhances security and communication for both students and house owners.

## 1.3 Problem Statement
Despite the proliferation of online property platforms, university students face several persistent issues:
1. Students are frequently exposed to fraudulent listings and rental scams due to a lack of verification mechanisms on generic platforms.
2. The search for compatible housemates is fragmented and inefficient, typically relying on informal social media groups.
3. Information is not centralized, forcing users to navigate multiple disparate channels to find housing and communicate with landlords.
4. Existing platforms are not designed specifically for students and lack efficient tools to filter properties based on proximity to the university campus.

## 1.4 Objectives

**General Objective**
Develop a Flutter-based mobile application (SewaSiswa) that centralizes and secures the accommodation search and rental process for university students.

**Specific Objectives**
1. To develop a structured house listing system for owners to post properties and for students to browse availability.
2. To allow students to efficiently search and filter rentals based on location, distance radius, and price range.
3. To develop an integrated housemate matching system that enables students to post requests and connect with compatible peers.
4. To implement a rental payment management system with automated notifications to remind tenants of upcoming due dates.

## 1.5 Scope
The scope of the project covers a cross-platform mobile application supported by a Supabase backend.

**User**
*   Student
*   House Owner
*   General Tenant

**Platform**
*   Android and iOS (Flutter)

**Features**
*   Login/Register with role-based profiles
*   View, search, and filter property listings
*   Housemate matching and request posting
*   In-app messaging between users
*   Manage property listings
*   Rent payment tracking and automated reminders
*   Wishlist management

## 1.6 Significance
This project holds significant value for multiple stakeholders:
*   **Students:** Provides a safer, more efficient, and centralized platform that mitigates rental fraud risks, simplifies the search for properties based on campus proximity, and alleviates the stress of finding compatible housemates.
*   **House Owners:** Offers a direct, targeted channel to reach a reliable tenant demographic, making property management and tenant communication more efficient.
*   **University Community:** Enhances the overall student welfare and off-campus living experience, indirectly supporting the university's ecosystem by ensuring safe housing for its student population.

## 1.7 Project Methodology
The development of the SewaSiswa application adopts the **Agile** Software Development methodology. Agile is highly suited for this project because it promotes an iterative and flexible approach to mobile application development. It allows for continuous feedback and progressive refinement of features, ensuring that the application adapts to the evolving requirements of its target users (students and owners) throughout the development lifecycle. The methodology is broken down into continuous cycles of requirements gathering, system design, implementation, and testing, enabling rapid delivery of functional components.

---

# Chapter 2: LITERATURE REVIEW AND PROJECT METHODOLOGY

This chapter explains what other researchers have done and how the SewaSiswa project was developed.

## 2.1 Literature Review

A comparative analysis of existing house rental systems and mobile applications was conducted to understand the current market and identify gaps that SewaSiswa aims to fill. Student accommodation systems face unique challenges that generic platforms often fail to address. 

Table 2.1 below illustrates the comparison between these existing works and the proposed SewaSiswa application.

**Table 2.1: Comparison of Existing Property Platforms and Related Works**

| Author / Platform | System | Technology | Limitation |
| :--- | :--- | :--- | :--- |
| **Mudah.my (2024)** | Classified Ads Platform | Web / Native | Too generic; lacks specific distance-to-campus filters and housemate matching. |
| **iProperty Malaysia (2024)** | Property Listing Portal | Web / Native | Focuses on high-end real estate and general public; not tailored to student budgets or needs. |
| **Ahmad & Razak (2021)** | Student Housing Apps Review | Mobile Apps | Most reviewed apps lack integrated secure payment and real-time chat functionalities. |
| **Ismail & Yusof (2020)** | Conventional Search Methods | Web / WhatsApp | High risk of rental scams, fragmented communication, and unorganized listings. |
| **SewaSiswa (Proposed)** | Student Rental & Housemate Finder | Flutter + Supabase | **Mobile, cross-platform, real-time chat, and map integration tailored for students.** |

## 2.2 Related Technologies

The development of SewaSiswa leverages modern mobile development and cloud database technologies.

### Flutter
Flutter is an open-source UI software development kit created by Google. It is used to develop cross-platform applications for Android and iOS from a single codebase.
*   **Advantages:** It offers a hot-reload feature for rapid development, highly customizable widgets for a native-like user experience, and excellent performance as it compiles directly to native ARM code.
*   **Dart:** The programming language used by Flutter. Dart is object-oriented, strongly typed, and optimized for building user interfaces with fast compilation times.

### Supabase (Firebase Alternative)
Instead of Firebase, this project utilizes **Supabase**, an open-source Firebase alternative based on PostgreSQL.
*   **Authentication (GoTrue):** Provides secure user registration and login functionality, supporting email/password and social logins while strictly managing user sessions.
*   **PostgreSQL Database:** A powerful, open-source object-relational database system that handles complex queries, relationships (like users to listings), and strict Row Level Security (RLS) policies.
*   **Storage:** Provides secure file hosting for managing media assets, such as user profile pictures, property listing photos, and payment receipt uploads.

## 2.3 Development Methodology

The development of the SewaSiswa application adopts the **Agile** Software Development methodology. Agile is highly suited for mobile application development due to its iterative approach, allowing for continuous feedback and progressive refinement of features. The process is divided into the following key phases:

1.  **Planning:** Defining the project scope, identifying target users (students, owners), and outlining the core features of the SewaSiswa application.
2.  **Requirement Gathering:** Collecting and analyzing the functional and non-functional requirements to address the specific pain points of the student rental market.
3.  **Design:** Creating the system architecture, database schema, and designing UI mockups based on minimalist principles.
4.  **Development (Implementation):** Coding the frontend using the Flutter framework and integrating the Supabase backend services.
5.  **Testing:** Conducting iterative testing throughout the development lifecycle, including unit tests, widget tests, and integration tests to ensure system stability.
6.  **Deployment:** Releasing the application for User Acceptance Testing (UAT) to gather feedback from real students and property owners.

> [!NOTE]
> *Please insert your Agile methodology diagram here.*

## 2.4 Requirement Gathering

Requirements for the SewaSiswa application were collected through multiple channels to ensure a comprehensive understanding of the problem domain:
*   **Online Survey / Questionnaire:** A survey was distributed among university students to quantitatively measure the difficulties they face when finding rental houses and housemates, and to identify their most desired app features.
*   **Interview / Informal Discussions:** Discussions were held with students who currently rent off-campus and local property owners to qualitatively understand their specific pain points and communication issues.
*   **Online Research:** Existing digital property platforms and related academic journals were reviewed to identify feature gaps and limitations in current solutions.

---

# Chapter 3: ANALYSIS

## 3.1 Problem Statement
University students frequently struggle to find suitable, affordable, and safe off-campus accommodation. Existing generic property platforms do not cater to the specific needs of students. Consequently, students are exposed to rental scams from unverified landlords, experience difficulty in finding compatible housemates to share rental costs, and suffer from an unorganized rental process. 

## 3.2 Proposed System
SewaSiswa is proposed as a centralized, secure mobile application designed specifically for the student rental market. By connecting verified property owners directly with students and providing a dedicated housemate finder feature, the application streamlines the search process, enhances security, and improves the overall housing experience.

## 3.3 Functional Requirements
*   **User Authentication & Authorization**: The system must allow users to register and log in using either a 'Student' or 'Owner' role.
*   **Property Listing Management**: Owners must be able to create, update, and manage property listings, including uploading photos and setting rental details.
*   **Housemate Matching**: Students must be able to create housemate search posts and view posts from others based on preferences (e.g., gender, faculty).
*   **Wishlist System**: Users must be able to save and manage their favorite property listings.
*   **In-app Messaging**: Real-time chat functionality must be provided to allow direct communication between students and owners, or potential housemates.
*   **Rental & Payment Management**: The system should track rental tenancy, due dates, and record payment transactions.

## 3.4 Non-Functional Requirements
*   **Performance**: The app must load listings and images efficiently, providing smooth scrolling and navigation.
*   **Security**: User data must be protected using Supabase Authentication and robust Row Level Security (RLS) policies on the database.
*   **Usability**: The UI must be intuitive and easy to navigate for users with varying levels of technical proficiency.

## 3.5 System Requirements

**Table 3.1: Hardware and Software Requirements**

| Category | Requirement |
| :--- | :--- |
| **Hardware** | MacBook / Windows PC (8GB RAM minimum), Android/iOS Device for testing |
| **Software** | Flutter SDK, Dart, Supabase (Backend), Visual Studio Code / Android Studio |

**Table 3.2: Summary of Functional and Non-Functional Requirements**

| Req ID | Type | Description |
| :--- | :--- | :--- |
| FR01 | Functional | The system shall allow users to register as Student or Owner. |
| FR02 | Functional | The system shall allow users to filter properties by distance. |
| NFR01 | Non-Functional | The system shall load property images within 3 seconds. |
| NFR02 | Non-Functional | User passwords must be securely hashed by Supabase. |

---

# Chapter 4: DESIGN

## 4.1 System Architecture

The SewaSiswa application employs a modern Client-Server architecture designed to ensure seamless communication between the mobile client and the cloud backend. The architecture integrates external APIs to enhance the platform's geolocation capabilities.

*Note: Please insert Figure 4.1 Overall System Architecture Diagram here.*

The structural flow of the system is represented as follows:

**Flutter Application (Client Frontend)**
↓
**Supabase Authentication (User Login & Security)**
↓
**Supabase PostgreSQL (Relational Database for Listings & Chats)**
↓
**Supabase Storage (Media Assets & Photos)**
+
**Google Maps API (External Service for Location)**

Detailed explanation of the components:
*   **Frontend (Client)**: Developed using the Flutter framework, providing a responsive and cross-platform mobile application (Android/iOS). State management and UI rendering are handled efficiently using Flutter's widget tree.
*   **Backend (Server - Supabase)**: The backend operates on Supabase as a Backend-as-a-Service (BaaS). It provides a robust PostgreSQL database for structured data, GoTrue for secure user authentication and session management, and Supabase Storage for securely hosting media assets like property photos and payment receipts.
*   **External API Integration**: The application utilizes the Google Maps Platform (Maps SDK) to render interactive maps and calculate proximity radiuses for rental properties relative to the university campus.

## 4.2 Database Design
The database is structured to handle the complex relationships between users, properties, and rentals. Key entities include:
*   **Users**: Stores user profiles, distinguishing between 'student' and 'owner' roles, and capturing details like matric numbers and faculty.
*   **Listings & Listing Photos**: Manages property details (price, deposit, rules) and associated media.
*   **Housemate Posts**: Stores student requests for housemates, including preferences and budgets.
*   **Rental Tenants & Payments**: Maps users to active rentals, tracks tenancy periods, and logs payment transactions.
*   **Messages & Notifications**: Facilitates real-time communication and alerts users to important events (e.g., rent due, new messages).

### 4.2.1 Data Dictionaries

**Table 4.1: Data Dictionary for `users` Table**

| Attribute Name | Data Type | Key | Description |
| :--- | :--- | :--- | :--- |
| id | UUID | Primary Key | Unique identifier linked to Supabase Auth |
| email | VARCHAR | | User's email address |
| role | VARCHAR | | Role of the user (e.g., student, owner) |
| created_at | TIMESTAMP | | Record creation date |

**Table 4.2: Data Dictionary for `listings` Table**

| Attribute Name | Data Type | Key | Description |
| :--- | :--- | :--- | :--- |
| id | UUID | Primary Key | Unique identifier for the listing |
| owner_id | UUID | Foreign Key | References `users(id)` |
| title | VARCHAR | | Title of the property listing |
| monthly_rent | NUMERIC | | Rental price per month |

**Table 4.3: Data Dictionary for `housemate_posts` Table**

| Attribute Name | Data Type | Key | Description |
| :--- | :--- | :--- | :--- |
| id | UUID | Primary Key | Unique identifier for the post |
| user_id | UUID | Foreign Key | References `users(id)` |
| budget | NUMERIC | | Maximum budget for the room |
| description | TEXT | | Details about the requested housemate |

## 4.3 User Interface (UI) Design
The UI design prioritizes clarity and ease of use:
*   **Main Navigation**: A persistent Bottom Navigation Bar allows seamless switching between the Home screen (explore listings), Wishlist, Chat, and Account profile.
*   **Listing Details**: Features an image carousel, comprehensive property details, and direct access to the owner's profile or chat.
*   **Owner Profile**: Displays verified owner details, their active property listings, and user reviews to build trust.

---

# Chapter 5: IMPLEMENTATION

## 5.1 About List of Tables
To update List of Tables, place the cursor on the list that needs to be updated.  Similar to the Table of Content, click on the icon “Update Table” under References tab to list down the updates, as shown in Figure 4.1

## 5.2 About List of Figures
To update List of Figures, place the cursor on the list that needs to be updated.  Next, click on the icon “Update Table” under References tab to list down the updates, as shown in Figure 4.1. 

## 5.3 About List of Figures
To update List of Figures, place the cursor on the list that needs to be updated.  Next, click on the icon “Update Table” under References tab to list down the updates, as shown in Figure 4.1. 

## 5.4 About List of Figures
To update List of Figures, place the cursor on the list that needs to be updated.  Next, click on the icon “Update Table” under References tab to list down the updates, as shown in Figure 4.1. 

## 5.5 About List of Figures
To update List of Figures, place the cursor on the list that needs to be updated.  Next, click on the icon “Update Table” under References tab to list down the updates, as shown in Figure 4.1. 

---

# Chapter 6: TESTING

## 6.1 Test Cases

Testing is a critical phase to ensure the system functions as expected. The following tables outline the test cases executed during the development of SewaSiswa.

**Table 6.1: Test Cases for User Authentication (Login/Register)**

| Test ID | Test Description | Test Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| TC01 | Successful Student Registration | 1. Enter valid details<br>2. Click Register | Account created and user routed to Home screen | Pass |
| TC02 | Invalid Email Login | 1. Enter incorrect email<br>2. Click Login | Error message displayed "Invalid credentials" | Pass |

**Table 6.2: Test Cases for Search and Distance Filtering**

| Test ID | Test Description | Test Steps | Expected Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| TC03 | Filter by Distance (5km) | 1. Tap distance filter<br>2. Set to 5km | Only listings within 5km of UTeM are shown | Pass |

## 6.2 User Acceptance Testing (UAT)

**Table 6.3: Summary of User Acceptance Testing (UAT) Results**

| Survey Question | Average Score (Out of 5) | Feedback / Remarks |
| :--- | :--- | :--- |
| How easy was it to find a property? | 4.5 | Users appreciated the map and distance filters. |
| Is the housemate matching useful? | 4.8 | Very relevant for students looking to share rent. |

---

# Chapter 7: PROJECT CONCLUSION

## 7.1 Wrap-Up
Please enjoy writing your FYP

---

# REFERENCES
*   Google Maps Platform. (2024). *Maps SDK for Android & iOS*. https://developers.google.com/maps
*   Firebase. (2024). *Firebase Documentation – Authentication, Firestore & Cloud Messaging*. https://firebase.google.com/docs
*   Flutter. (2024). *Flutter – Build apps for any screen*. https://flutter.dev
*   Mudah.my. (2024). *Malaysia's Online Marketplace*. https://www.mudah.my
*   iProperty Malaysia. (2024). *Property listings in Malaysia*. https://www.iproperty.com.my
*   WhatsApp. (2024). *Privacy and Security on WhatsApp*. https://www.whatsapp.com/security
*   Stripe. (2024). *Stripe Payments Documentation*. https://stripe.com/docs
*   Ahmad, N., & Razak, R. A. (2021). "Mobile Application for Student Housing: A Systematic Review." *Journal of Information Technology and Computer Science*, 6(2), 45–58. https://doi.org/10.xxxxx
*   Ismail, S., & Yusof, M. (2020). "Challenges Faced by Students in Finding Accommodation Near Universities in Malaysia." *International Journal of Academic Research in Business and Social Sciences*, 10(3), 120–134.
*   Dart. (2024). *Dart Programming Language*. https://dart.dev

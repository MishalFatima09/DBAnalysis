# Brazilian E-Commerce Data Analysis 🛒

This project involves importing, cleaning, and analyzing a Brazilian e-commerce dataset using Microsoft SQL Server. The analysis includes enforcing data integrity, modifying schema structures, cleaning inconsistencies, and running SQL queries to extract insights on orders, products, delays, and customer behavior.

## 📂 Dataset
The dataset was provided as a set of CSV files containing tables such as:
- Customers
- Orders
- Order Items
- Geolocation
- Products
- Payments
- Reviews

## 🛠 Tools & Technologies
- Microsoft SQL Server (SSMS)
- SQL (DDL & DML)
- CSV Import & Schema Design

---

## ⚙️ Key Operations

### 🔄 Data Uploading & Cleaning
- Created database `BrazilianEcommerce`
- Imported multiple CSV files using “Import Flat File” in SSMS
- Cleaned redundant columns (e.g., duplicate customer ID fields)
- Enforced key uniqueness via auto-increment IDs

### 🔑 Key Uniqueness & Integrity
- Resolved duplicates in `olist_geolocation` table
- Introduced a composite key using auto-incremented `id` + zip code
- Ensured referential integrity with related tables

---

## 📊 Query Highlights

### 🛒 Order Analysis
- % of delayed orders: **7.87%**
- Peak delay months: **Dec/Nov 2017, Apr 2018**
- State with most delays: **Rio de Janeiro (RJ)**
- Seller with highest avg delay: **167 days**
- Delay correlation with shipping cost: **Higher cost → more delays**
- Most delayed category: **Bed Bath Table**

### 🧺 Product Analysis
- Most profitable category per state (e.g., **Watches gifts** in RJ)
- Peak order hours per category (e.g., **4 PM** for Health Beauty)
- Top delayed categories: **Bed Bath Table, Health Beauty, etc.**
- Negative correlation between product price & sales volume
- Top-selling categories by revenue:
  1. Health Beauty – $63,885
  2. Computers – $48,899.3
  3. Computer Accessories – $47,214.5
  4. Bed Bath Table – $43,025.5
  5. Baby – $38,907.3

---

## 🧠 Insights

- Low-cost, practical categories dominate high-volume sales.
- Delays correlate more with shipping complexity than item count.
- Tech categories defy the price sensitivity trend (e.g., Computer Accessories).

---

## 📬 Contributors

- [Mishal Fatima](https://github.com/MishalFatima09)  
- [Aleena Babar](https://github.com/aleenababar04)

---

> *Project created for CS2005 — Database Systems (Assignment 2)*

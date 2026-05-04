# Airport Ticketing System

A comprehensive SQL Server relational database system for airport operations, designed to manage passenger ticketing, flight tracking, staff operations, and role-based access control.

## Overview

This database system provides a complete solution for airport ticketing operations, from passenger management through payment processing. It implements industry-standard practices for data integrity, security, and operational efficiency.

### Key Features

- **Role-Based Access Control**: Separate permissions for ticketing staff and supervisors
- **Comprehensive Passenger Management**: Complete passenger records with demographic and emergency contact information
- **Flight Operations**: Real-time flight tracking with seat availability management
- **Ticket Management**: Full ticketing workflow including pricing, taxes, and ancillary services
- **Payment Processing**: Secure payment tracking with multiple payment methods
- **Baggage Handling**: Integrated baggage tracking and fee calculation
- **Audit Logging**: Complete audit trail for compliance and security
- **Business Intelligence**: Pre-built views and functions for operational analysis

## Schema

The database consists of 10 core tables:

- **EMPLOYEE**: Ticketing staff and supervisor accounts with authentication
- **PASSENGER**: Passenger information and emergency contacts
- **FLIGHT**: Flight details including routes, times, and capacity
- **SEAT**: Aircraft seating configuration by class
- **RESERVATION**: Booking records with status tracking
- **TICKET**: Issued tickets with pricing and meal preferences
- **BAGGAGE**: Luggage tracking and fee management
- **ADDITIONAL_SERVICES**: Ancillary service purchases
- **PAYMENT**: Transaction records and payment methods
- **AUDIT_LOG**: Security and compliance audit trail

## Setup

### Prerequisites

- SQL Server 2016 or later
- SQL Server Management Studio (SSMS) or equivalent T-SQL client

### Installation

1. Connect to your SQL Server instance
2. Run the schema.sql file to create the database and all tables
3. Sample data will be automatically populated

```sql
-- Execute in SQL Server Management Studio
USE AirportTicketingSystem;
GO
```

## Features

### Views

- **vw_SeniorPendingPassengers**: Identifies passengers over 40 with pending reservations
- **vw_EmployeeRevenue**: Employee performance metrics and revenue contributions
- **vw_FlightCapacityAlert**: Alerts for flights approaching full capacity

### Stored Procedures

- **usp_SearchPassengersByName**: Search passengers by last name with travel history
- **usp_GetBusinessClassMealsToday**: List business class meals required for today
- **usp_AddEmployee**: Create new employee accounts with security credentials
- **usp_UpdatePassenger**: Update passenger contact and emergency information

### Functions

- **ufn_GetCheckedBaggageCount**: Count checked-in baggage for a flight on a specific date
- **ufn_GetPassengerTravelHistory**: Retrieve complete travel history for a passenger

### Triggers

- **trg_UpdateSeatStatus**: Automatically update seat preferences when tickets are issued

## Sample Data

The schema includes sample data representing:

- 6 employees (2 supervisors, 4 ticketing staff)
- 18 passengers with varied demographics
- 5 flights across multiple routes
- 200 seats per flight with class distribution (first/business/economy)
- 18 reservations with mixed status (confirmed/pending/cancelled)
- 5 issued tickets with associated baggage and payments

## Queries Included

Pre-built analytical queries demonstrate:

- Passenger search and filtering
- Revenue analysis by employee
- Flight capacity monitoring
- Booking status reporting
- Meal preference tracking
- Baggage compliance

## Technology

- **Database**: SQL Server 2016+
- **Language**: T-SQL
- **Constraints**: Foreign keys, check constraints, unique constraints
- **Indexes**: Optimized for common queries on flights, seats, and tickets

## Security

The system implements:

- Password hashing with salt storage for employee accounts
- Role-based database access control
- Foreign key constraints for data integrity
- Comprehensive audit logging of all operations
- Check constraints for business logic enforcement

## Notes

- All sample dates use 2023 data and should be updated for production use
- Employee passwords in sample data are placeholders and must be replaced
- The constraint on future reservations can be modified if historical bookings are needed
- Flight capacity calculations include available seat tracking

## License

This project is provided as-is for professional use.

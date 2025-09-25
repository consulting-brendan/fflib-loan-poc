# Mortgage Application System

A Salesforce proof-of-concept implementing a simplified mortgage application process using Apex Enterprise Patterns (fflib).

## Project Structure

The solution implements loan application processing using fflib architecture:
- **Loan Application Processing**: Submit Application (validation, product selection, task creation)

## Loan Application Processing

### Process Flow
```
Broker → Create Contact → Create Product → Create Loan Application → Update Status (Draft→Submitted) → System Validation → Product Selection → Task Assignment
```

### Architecture Components

#### Triggers
- **`LoanApplications.trigger`** - Main trigger delegating to domain handler

#### Trigger Handlers  
- **`LoanApplicationsTriggerHandler.cls`** - Extends fflib_SObjectDomain, handles trigger events

#### Domain Layer
- **`LoanApplications.cls`** - Core business logic for loan processing, validation, and approval
- **`ILoanApplications.cls`** - Interface defining loan application domain contract
- **`Products.cls`** - Product selection logic based on credit scores
- **`IProducts.cls`** - Interface defining product domain contract

#### Selector Layer
- **`LoanApplicationsSelector.cls`** - Data access for Loan_Application__c records
- **`ILoanApplicationsSelector.cls`** - Interface for loan application queries
- **`ContactsSelector.cls`** - Data access for Contact records (borrowers)
- **`IContactsSelector.cls`** - Interface for contact queries
- **`ProductsSelector.cls`** - Data access for Product__c records
- **`IProductsSelector.cls`** - Interface for product queries

#### Service Layer
- **`LoanApplicationServiceImpl.cls`** - Service implementation orchestrating loan processing
- **`ILoanApplicationService.cls`** - Interface defining service contract

#### Supporting Domain Classes
- **`Contacts.cls`** - Contact domain logic for activity updates
- **`IContacts.cls`** - Interface for contact domain operations

### How to Run Tests
```bash
# Run all Loan Application tests
sf apex test run \
  --classnames LoanApplicationsSelectorTest,ContactsSelectorTest,LoanApplicationsTest,ProductsTest,LoanApplicationsTriggerHandlerTest \
  --result-format human \
  --code-coverage \
  --wait 10

# Run specific test classes
sf apex test run --tests LoanApplicationsTriggerHandlerTest.testStatusChangeFromDraftToSubmittedWithDML --synchronous
```

### Test Coverage
- **Selector Tests**: `LoanApplicationsSelectorTest`, `ContactsSelectorTest` - Data access layer validation
- **Domain Tests**: `LoanApplicationsTest`, `ProductsTest` - Business logic validation  
- **Trigger Tests**: `LoanApplicationsTriggerHandlerTest` - End-to-end trigger workflow testing

### Design Notes & Trade-offs

**Architecture Decisions:**
- **Domain Layer**: `LoanApplications` — validation, approval/rejection rules, product selection
- **Service Layer**: `LoanApplicationServiceImpl` — orchestrates domain logic via selectors
- **Selector Layer**: `ContactsSelector`, `ProductsSelector`, `LoanApplicationsSelector` — data access with FLS
- **Trigger**: Delegates to `LoanApplicationsTriggerHandler` using fflib_SObjectDomain pattern

**fflib Implementation:**
- **SObjectDomain**: Trigger handler extends fflib_SObjectDomain for trigger context management
- **SObjectSelector**: All selectors extend fflib_SObjectSelector for consistent query patterns
- **ISObjects**: Domain classes extend fflib_SObjects for collection management
- **Application Factory**: Centralized factory pattern for selector, domain, and service instantiation
- **Unit of Work**: fflib_ISObjectUnitOfWork for transactional DML operations

**Key Features:**
- **Validation**: Borrower email, income > 0, credit score required
- **Product Selection**: Automatic best-rate product selection based on credit score
- **Status Management**: Draft → Submitted → Approved/Rejected workflow
- **Task Creation**: Automated broker task assignment for approved applications
- **Contact Activity**: Updates borrower contact description on approval/rejection

**Design Trade-offs:**
- **Data Model**: Used standard Contact instead of custom Borrower object, Loan_Application__c and Product__c
- **Validation Strategy**: Implemented in both trigger validation and domain submission methods
- **Task Assignment**: Generic broker task creation, would expand to role-based assignment with Custom Metadata
- **Error Handling**: Basic validation with field-level error attachment
- **Testing**: Comprehensive unit and integration tests with fflib mocking patterns

### Manual Testing Workflow

#### 1. Create Test Data
```apex
// Create borrower contact
Contact borrower = new Contact(
    FirstName = 'Test',
    LastName = 'Borrower',
    Email = 'test@example.com',
    Annual_Income__c = 75000,
    Credit_Score__c = 800
);
insert borrower;

// Create products
List<Product__c> products = new List<Product__c>{
    new Product__c(Name = 'Premium Product', Min_Credit_Score__c = 750, Base_Rate__c = 0.05),
    new Product__c(Name = 'Standard Product', Min_Credit_Score__c = 650, Base_Rate__c = 0.08)
};
insert products;
```

#### 2. Create and Submit Loan Application
```apex
// Create loan application
Loan_Application__c app = new Loan_Application__c(
    Borrower__c = borrower.Id,
    Amount__c = 100000
    // Status defaults to 'Draft'
);
insert app;

// Submit application (triggers processing)
app.Status__c = 'Submitted';
update app;
```

#### 3. Verify Results
```apex
// Check application status
Loan_Application__c result = [SELECT Status__c, Product__c, Approval_Outcome__c FROM Loan_Application__c WHERE Id = :app.Id];
System.debug('Status: ' + result.Status__c);
System.debug('Product: ' + result.Product__c);
System.debug('Outcome: ' + result.Approval_Outcome__c);

// Check created task
List<Task> tasks = [SELECT Subject, Status FROM Task WHERE WhatId = :app.Id];
System.debug('Tasks created: ' + tasks.size());
```

## Development Setup

### Prerequisites
- Salesforce CLI
- Salesforce DX project
- Dev org with custom objects: `Loan_Application__c`, `Product__c`
- Custom fields on Contact: `Annual_Income__c`, `Credit_Score__c`

### Custom Object Fields

#### Loan_Application__c
- `Borrower__c` (Lookup to Contact)
- `Amount__c` (Currency)
- `Status__c` (Picklist: Draft, Submitted, Approved, Rejected)
- `Product__c` (Lookup to Product__c)
- `Approval_Outcome__c` (Text Area)

#### Product__c  
- `Min_Credit_Score__c` (Number)
- `Base_Rate__c` (Percent)

#### Contact (Custom Fields)
- `Annual_Income__c` (Currency)  
- `Credit_Score__c` (Number)

### Deployment
```bash
# Deploy all loan application components
sf project deploy start --source-dir sfdx-source/apex-common-samplecode/main/classes/domains/LoanApplications.cls --target-org [your-org]
sf project deploy start --source-dir sfdx-source/apex-common-samplecode/main/triggers/LoanApplications.trigger --target-org [your-org]

# Deploy test classes
sf project deploy start --source-dir sfdx-source/apex-common-samplecode/test/classes/domains/LoanApplicationsTest.cls --target-org [your-org]
```

## Learning Notes

This project demonstrates key fflib patterns:
- **Separation of Concerns**: Clear boundaries between trigger, domain, selector, and service layers
- **Factory Pattern**: Centralized object creation via Application factories  
- **Interface Segregation**: Each layer has corresponding interfaces for testability
- **Domain-Driven Design**: Business logic encapsulated in domain classes
- **Unit of Work**: Transactional integrity across multiple DML operations

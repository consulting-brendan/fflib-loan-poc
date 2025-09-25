/**
 * @description Trigger for Loan_Application__c object that delegates to LoanApplicationsTriggerHandler
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • fflib triggers are lightweight - they only delegate to domain handlers via fflib_SObjectDomain.triggerHandler()
 * • Covers all DML events (before/after insert/update/delete) but business logic lives in the handler class
 * • Uses the fflib pattern of passing the handler class type to enable framework-level trigger management
 * • Avoids complex trigger logic by leveraging the SObjectDomain framework for trigger context handling
 * • Enables easy testing through the handler class without requiring DML operations in unit tests
 **/

trigger LoanApplications on Loan_Application__c (
	after delete, after insert, after update, before delete, before insert, before update) 
{
	fflib_SObjectDomain.triggerHandler(LoanApplicationsTriggerHandler.class);
} 

public with sharing class Contacts extends fflib_SObjects
	implements IContacts
{
	public static final String ACCOUNT_ACTIVITY_DESCRIPTION = 'Contact Activity Recorded';

	public static IContacts newInstance(List<Contact> recordList)
	{
		return (IContacts) Application.Domain.newInstance(recordList);
	}
	
	public static IContacts newInstance(Set<Id> recordIdSet)
	{
		return (IContacts) Application.Domain.newInstance(recordIdSet);
	}
	
	public Contacts(List<Contact> sObjectList)
	{
		super(sObjectList, Schema.Contact.SObjectType);
	}

	public List<Contact> getContacts()
	{
		return (List<Contact>) getRecords();
	}

	public void setDescription(String description)
	{
		for (Contact contact : getContacts())
		{
			contact.Description = description;
		}
	}

	public void updateAccountActivity()
	{
		setDescription(ACCOUNT_ACTIVITY_DESCRIPTION + ' ' + System.today());
	}

	public class Constructor implements fflib_IDomainConstructor
	{
		public fflib_SObjects construct(List<Object> objectList)
		{
			return new Contacts((List<SObject>) objectList);
		}
	}
} 
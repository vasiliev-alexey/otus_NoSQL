Class Shop.Company Extends (%Persistent, %Populate)
{

Property Name As %String [ Required ];

Property Phone As %String;

Property DeliveryAddress As %String(MAXLEN = 500);

Index NameIndex On Name [ Unique ];

Storage Default
{
<Data name="CompanyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Phone</Value>
</Value>
<Value name="4">
<Value>DeliveryAddress</Value>
</Value>
</Data>
<DataLocation>^Shop.CompanyD</DataLocation>
<DefaultData>CompanyDefaultData</DefaultData>
<ExtentSize>12</ExtentSize>
<IdLocation>^Shop.CompanyD</IdLocation>
<IndexLocation>^Shop.CompanyI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>2</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>3</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="DeliveryAddress">
<AverageFieldSize>23.17</AverageFieldSize>
<Selectivity>8.3333%</Selectivity>
</Property>
<Property name="Name">
<AverageFieldSize>17.25</AverageFieldSize>
<Selectivity>8.3333%</Selectivity>
</Property>
<Property name="Phone">
<AverageFieldSize>14.75</AverageFieldSize>
<Selectivity>8.3333%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Shop.CompanyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

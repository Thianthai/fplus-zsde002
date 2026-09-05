@EndUserText.label: 'Process Type Mapping Data'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_ProcessTypeMappingD
  as select from ZTSD_PRCS_TY
  association to parent ZI_ProcessTypeMappingD_S as _ProcessTypeMappiAll on $projection.SingletonID = _ProcessTypeMappiAll.SingletonID
{
  key PROCESS_TYPE as ProcessType,
  DESCRIPTION as Description,
  TRAN_TYPE as TranType,
  SALES_ORDER_TYPE as SalesOrderType,
  SALES_ORGANIZATION as SalesOrganization,
  DISTRIBUTION_CHANNEL as DistributionChannel,
  DIVISION as Division,
  @Semantics.user.createdBy: true
  CREATED_BY as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  CREATED_AT as CreatedAt,
  @Semantics.user.lastChangedBy: true
  LAST_CHANGED_BY as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  LAST_CHANGED_AT as LastChangedAt,
  @Consumption.hidden: true
  1 as SingletonID,
  _ProcessTypeMappiAll
}

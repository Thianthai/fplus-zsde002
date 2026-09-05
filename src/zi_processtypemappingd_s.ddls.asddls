@EndUserText.label: 'Process Type Mapping Data Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Semantics.valueRange.maximum: '1'
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'ProcessTypeMappiAll'
  }
}
define root view entity ZI_ProcessTypeMappingD_S
  as select from I_Language
    left outer join ZTSD_PRCS_TY on 0 = 0
  association [0..*] to I_ABAPTransportRequestText as _ABAPTransportRequestText on $projection.TransportRequestID = _ABAPTransportRequestText.TransportRequestID
  composition [0..*] of ZI_ProcessTypeMappingD as _ProcessTypeMappingD
{
  @UI.facet: [ {
    id: 'ProcessTypeMappingD', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Process Type Mapping Data', 
    position: 1 , 
    targetElement: '_ProcessTypeMappingD'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _ProcessTypeMappingD,
  @UI.hidden: true
  max( ZTSD_PRCS_TY.LAST_CHANGED_AT ) as LastChangedAtMax,
  @ObjectModel.text.association: '_ABAPTransportRequestText'
  @UI.identification: [ {
    position: 1 , 
    type: #WITH_INTENT_BASED_NAVIGATION, 
    semanticObjectAction: 'manage'
  } ]
  @Consumption.semanticObject: 'CustomizingTransport'
  cast( '' as SXCO_TRANSPORT) as TransportRequestID,
  _ABAPTransportRequestText
}
where I_Language.Language = $session.system_language

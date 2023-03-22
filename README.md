# Mule 3 to Mule 4 Migration Toolkit
The mule migration toolkit is a Mule application intended to provide a consolidated list of assets, accelerators and utilities that would be required to execute the various phases of the [Mule 3.x Migration Blueprint](https://knowledgehub.mulesoft.com/s/article/Mule-3-to-Mule-4-Migration-Blueprint). The toolkit uses the [Mule Migration Assistant (MMA) JSON report](https://github.com/mulesoft/mule-migration-assistant#mule-migration-assistant-accepted-parameters) as an input to deliver most of the features described below.

## Purpose
This toolkit is intended to facilitate MuleSoft customers and partners, responsible for delivering the Mule 3 to Mule migration project, to help drive the various phases of the program. The features of the toolkit provide a mechanism to accelerate the execution of the migration program and bring in a level of consistency by analysing the JSON report of the MMA to provide insightful analysis for each application that needs to be migrated. 

## Features
The toolkit currently supports the following features:

### Effort Estimation - Migration
The tool uses the JSON report to derive the original complexity based on the number of Mule components, percentage automation for the Mule 3 migration based on the number of mule components migrated out of the total and a score calculated based on the detailed messages applying a wightage to the level (INFO, WARN, ERROR), key (type of error/ warn) and components (the mule component on which the error/ warn was reported). The score is then used to derive a rough order of magniture /effort in terms of T Shirt sizing to provide an indication on the scale of manual effort required.

#### Implementation Details
The effort estimation is provided through a Microsoft Excel output listing all the apps on which MMA was executed. MMA would produce a report for each application in a specific format which is used to generate the output. Here is an example [MMA report](src/test/resources/sample_data/json.json) for reference.

The file has a "General" sheet which provides a description of all the columns/ attributes included in the estimation, along with a summary of the total number of applications, average automation percentage across all apps etc. The "Estimate" sheet contains the attributes for each application and includes the following columns derived using the logic as explained below.

- Application Name -  Populated using the `projectName` field from the JSON report
- Original Complexity -  Derived using the `numberOfMuleComponents` field from the JSON report
- Percentage Automation -  Derived using the `numberOfMuleComponents` and `numberOfMuleComponentsMigrated` field from the JSON report
- Score -  Calculated by looping through all the `detailedMessages` array to derive the score using `level`, `key` and `component` from the JSON report. The effort complexity scores and how they above JSON elements are applied for the [Score Calculation](#score-calculation) is detailed in the section below. 
- Migration Effort (T Shirt Sizing) -  Derived from the _Score_ above based on a range and set to XS (Extra Small), S (Small), M (Medium), L (Large) and XL (Extra Large)
- Migration Effort (Days) -  Derived from the _Score_ above by multiplying by a factor to get the estimate in person days
- Summary (Auto Generated) -  Populated using all the `detailedMessages` array to list the `component` fields from the JSON report

##### Score Calculation
The score is used to quantify the manual migration effort by taking into account the `detailedMessages` from the JSON report which lists all components in the mule application where some sort of manual action is required. The score can be modified by tweaking any of the factors but in order to modify it is important to understand how each of the attributes from JSON is applied to derive the score. 

This is an example of an object from the detailedMessages array with the key attributes being `level`, `key` and `component` which are used to calculate the score

```json
    {
      "level": "WARN",
      "key": "expressions.melToDw",
      "component": "scheduler",
      "lineNumber": 102,
      "columnNumber": 36,
      "message": "The MEL expression could not be migrated to a DataWeave expression.",
      "filePath": "src/main/mule/schedules-broadcast-workers.xml",
      "documentationLinks": []
    }
``` 
###### level
The level attribute provides information on the type of the message which MMA has provided when trying to migrate a specific component. The level can have 3 possible values which are INFO, WARN and ERROR. The current weightage applied to this is as follows:
- **INFO**: **50%** of the individual score for the component
- **WARN**: **100%** of the individual score for the component
- **ERROR**: **200%** of the individual score for the component

This is defined in the property file as:
```yaml
score:
  weightage:
    level:
      INFO: "0.50"
      WARN: "1.00"
      ERROR: "2.00"
``` 
###### key
The key attribute provides information on the sub category/ area for the affected component which the MMA has provided the message for when trying to migrate the same. The key can be used to reduce the current weightage of a component and can be applied as follows:

- **Full**: **100%** of the individual score for the component. Typically this is applied to keys which indicate that full weightage of the score will be applied as the key doesn't provide any reduction to the overall effort
- **Partial**: **50%** of the individual score for the component. Typically this is applied to keys which indicate changes to the functionality by using alternate configuration on the same component to achieve the same logic in the migrated application
- **Minimal**: **25%** of the individual score for the component. Typically this is applied to keys which indicate small/ minimal changes to the functionality by tweaking some configuration
- **Cosmetic**: **10%** of the individual score for the component. Typically this is applied to keys which indicate removal of redunant code/ comments/ checks etc with no impact to the functionality

This is defined in the property file in a hierarchical manner as:
```yaml
score:
  weightage:
    key:
      default: "1.00"
      components:
        unsupported: "1.00"
        java: "1.00"
      expressions:
        melToDw: "0.50"
        emptyLiteral: "0.50"
      message:
        attributesToInboundProperties: "0.10"
        outboundProperties: "0.10"
        outboundPropertyEnricher: "0.25"
``` 
> **NOTE:**  The effort reduction for specific keys can be changed as desired. Also, when running the estimation tool it might encounter a "new" key which is not currently present in the application configuration. This can be identified from the **Summary (Auto Generated)** column of the spreadsheet. Once identified, the key can be added to the above list with appropriate effort reduction. Without this the default (Full Effort) calculation will be applied.
``` 
A default score was applied to calculate the manual effort for xx custom components (and their number of occurrences in the application) as the migration of these is not supported by MMA: 
key - sftp.addSeqNo(xx).
``` 

###### component
The component attribute provides information on the actual mule component which the MMA has provided the message for when trying to migrate the same. The component has individual weightage assigned to each which is derived as follows:

- **Simple Supported Configuration**: Assigned score of **2** for the type of component. Typically this is applied to setting payload, attributes, variables etc which was successfully migrated to MMA but an additional modfications on the configuration is suggested. For eg: set payload, set property, set variable etc
- **Simple Unsupported Configuration**: Assigned score of **5** for the type of component. Typically this is applied to standard connector/ component/ transformer configurations which MMA successfully migrates to a Mule 4 equivalent functionality but some additional modfications on the configuration is required to achieve the same functionality as Mule 3. For eg: Any Community or Select connector configurations and operations, choice, flow, unti-successful, async etc 
- **Medium Supported Configuration**: Assigned score of **10** for the type of component. Typically this is applied to standard connector/ component/ transformer configurations for which a Mule 4 equivalent functionality is available but the MMA doesn't provide the functionality to migrate. For eg: Any Community, Select or Premium connector configurations and operations. 
- **Medium Unsupported Configuration**: Assigned score of **15** for the type of component. Typically this is applied to unsupported configurations of medium complexity which requires additional modfications on the migrated Mule 4 components to achieve the same functionality as Mule 3. For eg: enricher, exception strategy, object store configuration, cache, scripting etc
as is but the same functionality can be achieved by an alternative configuration on Mule 4 which needs to be rewritten.
- **Complex Supported Component Configuration**: Assigned score of **30** for the type of component. Typically this is applied to components in Mule 3 code which is also supported on Mule 4 but the configuration itself cannot be migrated as is and an alternative configuration on Mule 4 needs to be written. For eg: db spring connection, pooling profile, spring cofiguration, expression component etc
- **Complex Unsupported Java Customisation**: Assigned score of **60** for the type of component. Typically this is applied to Java classes in Mule 3 code which cannot be migrated but with some modifications to the Java classes itself, the bulk of the custom logic can be migrated as is. For eg: custom transformers, custom objectstore, custom interceptors, custom validators, custom processors etc
- **Very Complex Unsupported Customisation**: Assigned score of **120** for the type of component. Typically this is applied to customisation used in Mule 3 code which cannot be migrated and needs to be reviewed to identify an equivalent Mule 4 implementaion. For eg: custom exception strategy, transaction manager etc
- **Very Complex Unsupported Component**: Assigned score of **180** for the type of component. Typically this is applied to components used in Mule 3 code which cannot be migrated and requires a redesign effort. For eg: custom connectors, Mule OAuth Module etc

This is defined in the property file in a hierarchical manner as:
```yaml
score:
  weightage:
    component:
      "default": "15"
      "foreach": "10"
      "http":
        "response": "2"
        "error-response": "10"
      "custom-processor": "60"
      "custom-object-store": "60"
      "custom-connector": "180"
      "custom-exception-strategy": "120"
      "component": "30"
      "transformer": "10"
      "exception-strategy": "15"
      "parse-template": "5"
      "configuration": "30"
``` 
> **NOTE:**  The score for specific components can be changed as desired. Also, when running the estimation tool it might encounter a "new" component which is not currently present in the application configuration. This can be identified from the **Summary (Auto Generated)** column of the spreadsheet. Once identified, the component can be added to the above list with appropriate score based on the guidelines above. Without this the default (Medium Unsupported Configuration) score will be applied. It is recommended to add the components only if it is part of the core Mule 3 modules. For eg the _custom-audit_ is a custom connector and only applies to specific customers so it may not make sense to add this to the global component configurations
``` 
A default score was applied to calculate the manual effort for xx custom components (and their number of occurrences in the application) as the migration of these is not supported by MMA: 
spring-object(xx), 
custom-audit:config(xx),
custom-audit:audit(xx),
file:filename-wildcard-filter(xx), 
ftp:connector(xx), 
``` 
###### DW & MEL Expressions
In addition to the `detailedMessages` from the MMA report, a score is also assigned for each DW and MEL expressions which couldn't be migrated. The following fields are used to multiply the score factor for each type of expression

```json
"numberOfMELExpressions": 407,
"numberOfMELExpressionsMigrated": 364,
"numberOfDWTransformations": 117,
"numberOfDWTransformationsMigrated": 117
``` 
The following score factor is used:
```yaml
score:
  weightage:
    MEL: "10"
    DW: "3"    
```

The final score for each application used in the estimation sheet is calulated as the sum of all the individual scores for each of the `detailedMessages` and the DW and MEL expressions score derived using the score factor and the number of expressions which failed to migrate. 

## Installation
Currently, the toolkit is hosted on CloudHub and is accessible through this link - https://mule324-migration-catalyst.uk-e1.cloudhub.io/. However, the source code is also available should any changes to the above weightage or scoring is desirable. The following steps can be used to deploy this Mule application to any runtime platform:
- Clone the repository
- Compress the RAML under src/main/resources/api folder and publish to Exchange
- Manage the API in the API Manager
- Create a new Private Key in JKS format and replace the file under src/main/resources/key folder
- Modify the sandbox-catalyst-properties.yaml to replace with the API ID, Key store path and alias obtained in the previous steps
- Modify the sandbox-catalyst-secure.yaml to replace with the encrypted value of the key store password
- Compile and deploy the application to CloudHub with additional properties: mule.env=sandbox-catalyst and secure.key=[secure properties password decryption key]
- Access the estimater using the URL - https://[app-name].[region].cloudhub.io

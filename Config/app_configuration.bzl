
def appConfig():
    appName = native.read_config("custom", "appName")
    productName = native.read_config("custom", "productName")
    apiUrl = native.read_config("custom", "apiUrl")
    valUrl = native.read_config("custom", "valUrl")
    lab = native.read_config("custom", "lab")
    pbundle = native.read_config("custom", "pbundle")

    apiId = native.read_config("custom", "apiId")
    apiHash = native.read_config("custom", "apiHash")
    appCenterId = native.read_config("custom", "appCenterId")
    isInternalBuild = native.read_config("custom", "isInternalBuild")
    isAppStoreBuild = native.read_config("custom", "isAppStoreBuild")
    appStoreId = native.read_config("custom", "appStoreId")
    appSpecificUrlScheme = native.read_config("custom", "appSpecificUrlScheme")
    buildNumber = native.read_config("custom", "buildNumber")
    return {
        "appName": appName,
        "productName": productName,
        "apiUrl": apiUrl,
        "valUrl": valUrl,
        "lab": lab,
        "pbundle": pbundle,

        "apiId": apiId,
        "apiHash": apiHash,
        "appCenterId": appCenterId,
        "isInternalBuild": isInternalBuild,
        "isAppStoreBuild": isAppStoreBuild,
        "appStoreId": appStoreId,
        "appSpecificUrlScheme": appSpecificUrlScheme,
        "buildNumber": buildNumber,
    }

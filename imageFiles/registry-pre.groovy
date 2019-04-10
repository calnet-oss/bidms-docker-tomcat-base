println "Loading registry-pre.groovy"

if (!System.getProperty("springloaded")) {
    println "registry-pre.groovy: Using JNDI"
    environments {
        development {
            registry.jndiDatasource.enabled = true
        }
    }
}
else {
  println "registry-pre.groovy: Not using JNDI"
}

registry.config.overrides.locations = [
  "file:/var/lib/tomcat8/bidms-config/registry-overrides.groovy",
  "file:/var/lib/tomcat8/bidms-config/${appName}-overrides.groovy"
]
registry.config.secrets.locations = [
  "file:/var/lib/tomcat8/bidms-config/registry-secrets.groovy",
  "file:/var/lib/tomcat8/bidms-config/${appName}-secrets.groovy"
]

println "Done loading registry-pre.groovy"

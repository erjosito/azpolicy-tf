# DRY policy to associate private endpoints to DNS zones

Azure Private Endpoints need to be associated to Azure Private DNS Zones so that clients can resolve the service's name to a private instead of to a public address. This association can be done manually, or automatically as described in [Private Link and DNS integration at scale](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale).


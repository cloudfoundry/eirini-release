## Scaling and High Availablity Configuration

There is a mixture of high availability and scaling available in eirini components.
Components responsible for reacting to configuration and events cannot be scaled, as such reactions should not be duplicated.
These use leadership elections to ensure only a single instance is active at a given time.
Others, which provide services, can be scaled horizontally providing both increased bandwidth and availability.

Scaling is configured using the replicas property of the deployment spec in both cases.

| Eirini Component            | Scaling type | Notes                                                                                                                                                                    |
| --------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| REST API                    | Horizontal   | Request to the API are distributed round robin to the instances by default (this is based on the Kubernetes Service)                                                     |
| CRD Controller              | HA only      | Leadership election in the controller runtime ensures only a single instance handles a given CR event (create, update, delete, etc.)                                     |
| Event Reporter              | HA only      | Leadership election in the controller runtime ensures only a single instance handles a given crash event                                                                 |
| Task Reporter               | HA only      | Leadership election in the controller runtime ensures only a single instance handles a given task completion event                                                       |
| Instance Index Env Injector | Horizontal   | Request to the hook service are distributed round robin to the instances by default (this is based on the Kubernetes Service). The registration job should not be scaled |
| Metrics Collector           | None         | Leadership election is required but not yet implemented, so do not scale this component                                                                                  |
| Route Collector             | None         | Leadership election is required but not yet implemented, so do not scale this component                                                                                  |

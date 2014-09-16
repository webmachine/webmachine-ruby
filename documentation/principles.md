### Principles

* Webmachine is implemented as a Finite State Machine. The "state" that the FSM is interested in is the state of your resource.

* To create a resource, create a new class that extends Webmachine::Resource, and override the relevant callbacks to describe "facts" about your resource. For example, what content types it provides (`content_types_accepted`), what HTTP methods it supports (`allowed_methods`), whether or not it exists (`resource_exists?`), and how the resource should be rendered (`to_json`).

* Each method should one thing only - single responsibility principle.

* Once an "end state" has been reached (for example, `resource_exists?` returns false to a GET request, which means a 404 response should be returned), the FSM will stop the decision flow, and return the relevant response code to the client. The implication of this is that callbacks later in the flow (eg. the method to render the resource) can rely upon the fact that the resource's existance has already been proven, that authorisation has already been checked etc. so there is no need for any `if object == nil` type boilerplate.

* Most callbacks can interrupt the decision flow by returning an integer response code. You generally only want to do this when new information comes to light, requiring a modification of the response.

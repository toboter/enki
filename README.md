# Enki

# Installation
To use `Enki` in your application, add this line to your Gemfile:

```ruby
  gem 'enki', git: 'https://github.com/toboter/enki.git'
```

After add it, run `bundle install`.

Next you need to load migrations of this gem, so execute in your Rails application:

```
rails enki_engine:install:migrations
rails db:migrate
```

Last step is to set your classes as `sharer` and `Enki`. If you use Marduk you don't need to set `sharer` because it is defined inside the gem for User and Group. 
You will need a User and a Group Model (unless you use Marduk)!

To do this include these methods at top of yout models. For example:

```ruby
# File app/models/user.rb (sharer)
class User < ActiveRecord::Base
  sharer

  #...
end

# File app/models/thing.rb (shareable)
class Thing < ActiveRecord::Base
  include Enki

  #...
end
```

# Usage

You can use some view helpers 

```ruby
<%= share_multiple_with(Class) %>
```
to load the view helper for multisharing on index page

```ruby
<%= shared_with(Instance) %>
```
for sharing a single object

You also get some new methods for the class where Enki is included:
Class methods:
* `is_actable` true if included
* `accessible_by(current_user)` returns all instances shared with the current_user or one of its groups
* `inaccessible` returns all instances which are not shared
* `published_records` returns all instances which are published
* `visible_for(current_user)` combines:
    `accessible_by(current_user)`, `inaccessible`, `published_records` if current_user.is_admin?
    `accessible_by(current_user)`, `published_records` if current_user.present?
    `published_records` if no user is logged in.

Instance methods:
* `accessible_through?(user)` checks if the object is published or shared to the given user or unassigned.
* `published?` 
* `record_publisher` gives the publisher User
* `created?`
* `record_creator` gives the creator User

# Todo
* roles/abilities
* record states: created draft(shared_to) review(shared_to says ready) published(by admin)
* notifications send to babili
* adding 'ON CONFLICT DO UPDATE' to insert statement in shareable controller add_multiple




# Shareable Models documentation
(https://github.com/redBorder/shareable_models)

# Models
A model can be `sharer` or `shareable`. This methods include some relations and add new methods to your class. `shareable` is included through actable.

## Sharer (User & Group)
Set a model as sharer. A sharer can share and receive resources. It has edit permissions on a resource if:
(is set through Marduk)

* It creates the resource (see [Shareable](#shareable))
* Another sharer shares the resource with him and edit permission is true.

Importants methods defined by sharer (User or Group).
(see [sharer.rb](https://github.com/redBorder/shareable_models/blob/master/lib/shareable_models/models/sharer.rb) for full documentation):

* `share(resource, to, edit)`: share a resource with another model (to). You can set edit permissions (false by default).
* `share_with_me(resource, from, edit)`: share a resource **from** another sharer to me. 
* `can_edit?(resource)`: check if a model can edit a resource.
* `throw_out(resource, sharer)`: throw out a sharer from a resource.
* `leave(resource)`: to leave resource. A creator/owner of a shareable resource can't leave it.
* `allow_edit?(resource, to)`: allow a model to edit a resource. If resource was never shared with model, a new relation is created.
* `prevent_edit?(resource, to)`: disable an user to edit a resource. If resource was never shared with model, relation won't be created.


Shareable (where Enki is included) models can be shared between sharers. 
Importants methods defined by sharer (see [shareable.rb](https://github.com/redBorder/shareable_models/blob/master/lib/shareable_models/models/shareable.rb) for full documentation):

* `share_it(from, to, edit)`: share the resource with **from** a model **to** another. You can set edit permissions (false by default).
* `editable_by?(from)`: check if resource is editable by given model.
* `throw_out(from, to)`: a sharer (**from**) throw out another (**to**) from a resource.
* `leave(sharer)`: sharer leaves resource. A creator/owner of a shareable resource can't leave it.
* `allow_edit?(from, to)`: a sharer (**from**) allow another (**to**) to edit a resource. If resource was never shared with model, a new relation is created.
* `prevent_edit?(from, to)`: a sharer (**from**) disable another (**to**) to edit a resource. If resource was never shared with model, relation won't be created.

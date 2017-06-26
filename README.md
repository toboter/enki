# Enki

## Installation

gem 'enki', git: 'https://github.com/toboter/enki.git'
gem 'shareable_models'

rails enki_engine:install:migrations
rails db:migrate

add 'include Enki' to any model you like to track on or you like to share.

"<%= share_multiple_with(Class) %>"
to load the view helper for multisharing on index page

"<%= shared_with(Instance) %>"
for sharing a single object
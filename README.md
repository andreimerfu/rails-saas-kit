# Summary

<span>
  <img src="https://raw.githubusercontent.com/saadeghi/daisyui-images/master/images/daisyui-logo/favicon-192.png" alt="" style="max-width: 100%;" width="100" height="100">
</span>
<span>
  <img itemprop="image" class="avatar" src="https://avatars.githubusercontent.com/u/4223?s=200&amp;v=4" width="100" height="100" alt="@rails" style="max-width: 100%;">
</span>

Kickstart your Rails app with [daisyui](https://daisyui.com/) The most popular, free and open-source component library for Tailwind CSS.
[See in live Demo](https://daisyui.labs.my/)

Current Main Branch: Rails 8.0 + esbuild

Rails 7.2 + esbuild: https://github.com/mkhairi/rails-daisyui-starter/tree/rails7

Rails 6 + webpacker: https://github.com/mkhairi/rails-daisyui-starter/tree/rails6

## Goals

This Rails daisyui starter template is designed to kickstart your Rails project with daisyui swiftly. It comes with some magic spells and is supposedly beginner-friendly. Keeping it as simple as it should be.

## Overview

- Pre-equipped essential stuff.
  - [heartcombo gems](https://github.com/heartcombo)
  - Inline Svg
  - Simple Navigation
  - Tinymce
  - ....

## Setup

Clone the repo

```
https://github.com/mkhairi/rails-daisyui-starter.git
```

Install ruby, nodejs for runtime dependencies. You might refer [gorails setup tutorial](https://gorails.com/setup) for initial setup development enviroment.

```
bundle install
yarn install
```

Set up and run the development server:

```
bin/setup
bin/dev
```

## Enhanced Logging System

This application includes an enhanced logging system that provides colorful, emoji-enhanced logs in development and structured JSON logs in production.

### Features

- **Development**: Colorful console output with emojis for better readability
- **Production**: Structured JSON logs for easy parsing and analysis
- **Context-rich**: Automatically includes request IDs, user IDs, and organization IDs
- **Performance**: Includes timing information for requests and service operations
- **Integration**: Seamlessly integrates with Rails, ActiveRecord, and dry-workflow services

### Usage

#### In Models

All models automatically include the `Loggable` concern through `ApplicationRecord`. This provides the following methods:

```ruby
# Basic logging with context
log_debug("Message")
log_info("Message")
log_warn("Message")
log_error("Message")
log_fatal("Message")

# Logging with additional context
log_info("User created", { email: user.email, plan: user.plan })

# Logging method execution with timing
log_method(:info, :expensive_calculation, "Calculating something important")

# Logging exceptions
begin
  # Some code that might raise an exception
rescue => e
  log_exception(e, :error, "Failed to process data")
end
```

#### In Controllers

All controllers automatically include the `ControllerLogging` concern through `ApplicationController`. This provides:

- Automatic logging of all requests with timing information
- Automatic logging of responses
- Automatic logging of exceptions
- Access to the same logging methods as models

#### In Service Objects

All service objects that include `ApplicationService` automatically include the `ServiceLogging` concern. This provides:

- Automatic logging of service calls with timing information
- Automatic logging of each step execution
- Automatic logging of success/failure results
- Access to the same logging methods as models

### Log Levels

- **TRACE**: Very detailed information, useful for debugging specific issues
- **DEBUG**: Detailed information, useful for debugging
- **INFO**: General information about system operation
- **WARN**: Warning messages that don't affect normal operation
- **ERROR**: Error messages that affect a specific operation
- **FATAL**: Critical errors that affect the entire application

### Development vs Production

In development, logs are colorful and include emojis for better readability:

- 🔍 TRACE
- 🐞 DEBUG
- ℹ️ INFO
- ⚠️ WARN
- ❌ ERROR
- 💀 FATAL

In production, logs are in JSON format for easy parsing and analysis.

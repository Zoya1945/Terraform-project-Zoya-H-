# Terraform Functions - Complete Guide

## What are Terraform Functions?

Terraform includes many built-in functions that you can use to transform and combine values. Functions are called with the syntax `function_name(argument1, argument2, ...)`.

## String Functions

### 1. **String Manipulation**
```hcl
locals {
  # Case conversion
  upper_name = upper("hello world")           # "HELLO WORLD"
  lower_name = lower("HELLO WORLD")           # "hello world"
  title_name = title("hello world")           # "Hello World"
  
  # String operations
  trimmed    = trim("  hello world  ", " ")   # "hello world"
  replaced   = replace("hello-world", "-", "_") # "hello_world"
  substring  = substr("hello world", 0, 5)    # "hello"
  
  # String tests
  starts_with_hello = startswith("hello world", "hello") # true
  ends_with_world   = endswith("hello world", "world")   # true
  contains_space    = strcontains("hello world", " ")    # true
}
```

### 2. **String Formatting**
```hcl
locals {
  # Format function
  formatted_number = format("%03d", 42)                    # "042"
  formatted_string = format("Hello %s!", "World")          # "Hello World!"
  formatted_mixed  = format("%s has %d items", "Box", 5)   # "Box has 5 items"
  
  # Format with multiple arguments
  server_name = format("%s-%s-%02d", var.environment, var.service, var.instance_number)
  
  # Format date
  timestamp = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
}
```

### 3. **String Splitting and Joining**
```hcl
locals {
  # Split string into list
  parts = split("-", "web-server-01")         # ["web", "server", "01"]
  
  # Join list into string
  joined = join("-", ["web", "server", "01"]) # "web-server-01"
  
  # Join with different separator
  csv_string = join(",", ["apple", "banana", "cherry"]) # "apple,banana,cherry"
}
```

## Collection Functions

### 1. **List Functions**
```hcl
locals {
  my_list = ["apple", "banana", "cherry", "apple"]
  
  # List operations
  list_length    = length(my_list)              # 4
  first_element  = element(my_list, 0)          # "apple"
  last_element   = element(my_list, -1)         # "apple"
  
  # List manipulation
  sorted_list    = sort(my_list)                # ["apple", "apple", "banana", "cherry"]
  unique_list    = distinct(my_list)            # ["apple", "banana", "cherry"]
  reversed_list  = reverse(my_list)             # ["apple", "cherry", "banana", "apple"]
  
  # List searching
  index_of_banana = index(my_list, "banana")    # 1
  contains_apple  = contains(my_list, "apple")  # true
  
  # List slicing
  slice_result = slice(my_list, 1, 3)           # ["banana", "cherry"]
  
  # Concatenate lists
  combined = concat(my_list, ["date", "elderberry"])
}
```

### 2. **Map Functions**
```hcl
locals {
  my_map = {
    name        = "web-server"
    environment = "production"
    owner       = "devops"
  }
  
  # Map operations
  map_keys   = keys(my_map)     # ["environment", "name", "owner"]
  map_values = values(my_map)   # ["production", "web-server", "devops"]
  
  # Lookup with default
  region = lookup(my_map, "region", "us-west-2")  # "us-west-2"
  
  # Merge maps
  merged_map = merge(my_map, {
    region = "us-west-2"
    tier   = "web"
  })
  
  # Zipmap - create map from two lists
  keys_list   = ["name", "type", "size"]
  values_list = ["server", "web", "large"]
  zipped_map  = zipmap(keys_list, values_list)
  # Result: { name = "server", type = "web", size = "large" }
}
```

### 3. **Set Functions**
```hcl
locals {
  set_a = toset(["apple", "banana", "cherry"])
  set_b = toset(["banana", "cherry", "date"])
  
  # Set operations
  union_set        = setunion(set_a, set_b)        # ["apple", "banana", "cherry", "date"]
  intersection_set = setintersection(set_a, set_b) # ["banana", "cherry"]
  difference_set   = setsubtract(set_a, set_b)     # ["apple"]
  
  # Check if set has product
  has_apple = setproduct(set_a, set_b)
}
```

## Numeric Functions

### 1. **Mathematical Operations**
```hcl
locals {
  numbers = [10, 20, 30, 5, 15]
  
  # Basic math
  minimum = min(numbers...)     # 5
  maximum = max(numbers...)     # 30
  sum_all = sum(numbers)        # 80
  
  # Absolute value
  absolute = abs(-42)           # 42
  
  # Ceiling and floor
  ceiling_val = ceil(4.2)       # 5
  floor_val   = floor(4.8)      # 4
  
  # Logarithms
  log_val = log(100, 10)        # 2
  
  # Power
  power_val = pow(2, 3)         # 8
  
  # Sign
  sign_positive = signum(42)    # 1
  sign_negative = signum(-42)   # -1
  sign_zero     = signum(0)     # 0
}
```

## Type Conversion Functions

### 1. **Type Conversions**
```hcl
locals {
  # String conversions
  string_to_number = tonumber("42")           # 42
  number_to_string = tostring(42)             # "42"
  bool_to_string   = tostring(true)           # "true"
  
  # Collection conversions
  list_to_set = toset(["a", "b", "c", "a"])  # Set with unique values
  set_to_list = tolist(toset(["a", "b"]))    # ["a", "b"]
  
  # Map to list conversions
  map_keys_list   = keys(var.tags)
  map_values_list = values(var.tags)
  
  # Type checking
  is_string = can(tostring(var.value))
  is_number = can(tonumber(var.value))
  is_bool   = can(tobool(var.value))
}
```

## Encoding Functions

### 1. **Base64 Encoding**
```hcl
locals {
  # Base64 operations
  original_text = "Hello, World!"
  encoded_text  = base64encode(original_text)  # "SGVsbG8sIFdvcmxkIQ=="
  decoded_text  = base64decode(encoded_text)   # "Hello, World!"
  
  # Base64 for user data
  user_data_script = base64encode(templatefile("${path.module}/user_data.sh", {
    server_name = "web-server"
  }))
}
```

### 2. **URL Encoding**
```hcl
locals {
  # URL encoding
  original_url = "https://example.com/path with spaces"
  encoded_url  = urlencode(original_url)
  
  # Query string building
  query_params = {
    name = "John Doe"
    age  = "30"
  }
  query_string = join("&", [
    for k, v in query_params : "${urlencode(k)}=${urlencode(v)}"
  ])
}
```

### 3. **JSON Operations**
```hcl
locals {
  # JSON encoding/decoding
  data_object = {
    name    = "web-server"
    port    = 80
    enabled = true
  }
  
  json_string = jsonencode(data_object)
  parsed_data = jsondecode(json_string)
  
  # YAML encoding
  yaml_string = yamlencode(data_object)
  yaml_data   = yamldecode(yaml_string)
}
```

## Filesystem Functions

### 1. **File Operations**
```hcl
locals {
  # Read file contents
  config_content = file("${path.module}/config.txt")
  
  # Check if file exists
  config_exists = fileexists("${path.module}/config.txt")
  
  # Get file hash
  file_md5    = filemd5("${path.module}/config.txt")
  file_sha1   = filesha1("${path.module}/config.txt")
  file_sha256 = filesha256("${path.module}/config.txt")
  
  # Base64 encode file
  file_base64 = filebase64("${path.module}/binary-file.dat")
}
```

### 2. **Template Functions**
```hcl
locals {
  # Template file
  nginx_config = templatefile("${path.module}/nginx.conf.tpl", {
    server_name = var.server_name
    port        = var.port
    ssl_enabled = var.ssl_enabled
  })
  
  # Directory listing
  config_files = fileset("${path.module}/configs", "*.conf")
}
```

### 3. **Path Functions**
```hcl
locals {
  # Path operations
  module_path = path.module      # Current module path
  root_path   = path.root        # Root module path
  cwd_path    = path.cwd         # Current working directory
  
  # Path manipulation
  config_dir  = dirname("/path/to/config.txt")   # "/path/to"
  config_file = basename("/path/to/config.txt")  # "config.txt"
  
  # Path joining
  full_path = "${path.module}/configs/app.conf"
}
```

## Date and Time Functions

### 1. **Time Operations**
```hcl
locals {
  # Current timestamp
  current_time = timestamp()
  
  # Format timestamp
  formatted_time = formatdate("YYYY-MM-DD", timestamp())
  iso_time       = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
  
  # Time arithmetic
  future_time = timeadd(timestamp(), "24h")
  past_time   = timeadd(timestamp(), "-1h")
  
  # Time parsing
  parsed_time = strftime("%Y-%m-%d", timestamp())
}
```

## Network Functions

### 1. **CIDR Functions**
```hcl
locals {
  vpc_cidr = "10.0.0.0/16"
  
  # CIDR operations
  network_address = cidrhost(vpc_cidr, 0)        # "10.0.0.0"
  first_host      = cidrhost(vpc_cidr, 1)        # "10.0.0.1"
  broadcast       = cidrhost(vpc_cidr, -1)       # "10.0.255.255"
  
  # Subnet calculation
  subnet_cidrs = [
    for i in range(4) : cidrsubnet(vpc_cidr, 8, i)
  ]
  # Results: ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  # Network mask
  netmask = cidrnetmask(vpc_cidr)               # "255.255.0.0"
}
```

## Conditional Functions

### 1. **Conditional Logic**
```hcl
locals {
  # Conditional expression
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  
  # Coalesce - return first non-null value
  region = coalesce(var.region, var.default_region, "us-west-2")
  
  # Coalescelist - return first non-empty list
  subnets = coalescelist(var.custom_subnets, var.default_subnets, ["subnet-default"])
}
```

### 2. **Error Handling**
```hcl
locals {
  # Try function - handle potential errors
  safe_number = try(tonumber(var.maybe_number), 0)
  safe_lookup = try(var.config.database.host, "localhost")
  
  # Can function - test if expression is valid
  is_valid_cidr = can(cidrhost(var.cidr_block, 0))
  is_valid_json = can(jsondecode(var.json_string))
  
  # Sensitive function - mark value as sensitive
  db_password = sensitive(var.database_password)
}
```

## Advanced Function Patterns

### 1. **Complex Transformations**
```hcl
locals {
  # Transform list of objects
  servers = [
    { name = "web-1", type = "web", size = "small" },
    { name = "web-2", type = "web", size = "large" },
    { name = "db-1", type = "db", size = "medium" }
  ]
  
  # Group by type
  servers_by_type = {
    for server in local.servers : server.type => server...
  }
  
  # Create map with computed keys
  server_configs = {
    for server in local.servers : server.name => {
      instance_type = server.size == "small" ? "t3.micro" : (
        server.size == "medium" ? "t3.small" : "t3.large"
      )
      monitoring = server.type == "db" ? true : false
    }
  }
  
  # Flatten nested structures
  all_tags = flatten([
    for server in local.servers : [
      for key, value in server : {
        server_name = server.name
        tag_key     = key
        tag_value   = value
      }
    ]
  ])
}
```

### 2. **Dynamic Resource Creation**
```hcl
locals {
  # Create security group rules dynamically
  security_rules = flatten([
    for port in var.allowed_ports : [
      {
        type        = "ingress"
        from_port   = port
        to_port     = port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  ])
  
  # Generate subnet configurations
  subnet_configs = {
    for i, az in var.availability_zones : "subnet-${i}" => {
      cidr_block        = cidrsubnet(var.vpc_cidr, 8, i)
      availability_zone = az
      public           = i < var.public_subnet_count
    }
  }
}
```

### 3. **Validation Functions**
```hcl
variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "instance_types" {
  description = "List of instance types"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for instance_type in var.instance_types : 
      can(regex("^[tm][0-9]", instance_type))
    ])
    error_message = "All instance types must start with 't' or 'm' followed by a number."
  }
}
```

## Function Composition

### 1. **Chaining Functions**
```hcl
locals {
  # Chain multiple functions
  processed_name = lower(trim(replace(var.raw_name, " ", "-"), " -"))
  
  # Complex data transformation
  normalized_config = {
    for key, value in var.raw_config : 
    lower(key) => can(tonumber(value)) ? tonumber(value) : lower(value)
  }
  
  # Multi-step processing
  server_names = [
    for i in range(var.server_count) : 
    format("%s-%s-%02d", 
      lower(var.environment), 
      lower(var.service_name), 
      i + 1
    )
  ]
}
```

### 2. **Custom Function-like Locals**
```hcl
locals {
  # Function-like local for generating tags
  generate_tags = {
    base = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project_name
    }
    
    for_resource = {
      instance = merge(local.generate_tags.base, {
        Type = "compute"
      })
      
      database = merge(local.generate_tags.base, {
        Type = "database"
        Backup = "required"
      })
    }
  }
  
  # Function-like local for CIDR calculations
  network_calculator = {
    vpc_cidr = var.vpc_cidr
    
    public_subnets = [
      for i in range(var.public_subnet_count) :
      cidrsubnet(local.network_calculator.vpc_cidr, 8, i)
    ]
    
    private_subnets = [
      for i in range(var.private_subnet_count) :
      cidrsubnet(local.network_calculator.vpc_cidr, 8, i + var.public_subnet_count)
    ]
  }
}
```

## Best Practices

### 1. **Function Usage Guidelines**
```hcl
# Use descriptive variable names
locals {
  # Good
  formatted_server_name = format("%s-%s-%02d", var.environment, var.service, var.index)
  
  # Bad
  name = format("%s-%s-%02d", var.env, var.svc, var.i)
}

# Handle edge cases
locals {
  # Safe list access
  first_subnet = length(var.subnet_ids) > 0 ? var.subnet_ids[0] : null
  
  # Safe map access
  region = try(var.config.region, "us-west-2")
  
  # Validate inputs
  valid_cidr = can(cidrhost(var.cidr_block, 0)) ? var.cidr_block : "10.0.0.0/16"
}
```

### 2. **Performance Considerations**
```hcl
# Cache expensive operations
locals {
  # Calculate once, use multiple times
  availability_zones = data.aws_availability_zones.available.names
  
  subnet_configs = {
    for i, az in local.availability_zones : i => {
      az         = az
      cidr_block = cidrsubnet(var.vpc_cidr, 8, i)
    }
  }
}

# Avoid nested loops where possible
locals {
  # Efficient
  all_combinations = setproduct(var.environments, var.services)
  
  # Less efficient
  nested_combinations = flatten([
    for env in var.environments : [
      for svc in var.services : {
        environment = env
        service     = svc
      }
    ]
  ])
}
```

## Conclusion

Terraform functions provide powerful capabilities for data transformation, validation, and computation. Understanding and effectively using these functions enables you to create more dynamic, flexible, and maintainable Terraform configurations. Always consider readability, performance, and error handling when using functions in your code.
output "redis_cache_id" {
  description = "The ID of the Redis Cache instance"
  value       = azurerm_redis_cache.main_cache.id
}

output "resdis_hostname" {
  description = "The hostname of the Redis Cache instance"
  value       = azurerm_redis_cache.main_cache.hostname
}

output "redis_no_ssl_port" {
  description = "The non-SSL port of the Redis Cache instance"
  value       = azurerm_redis_cache.main_cache.port
}

output "redis_ssl_port" {
  description = "The SSL port of the Redis Cache instance"
  value       = azurerm_redis_cache.main_cache.ssl_port
}

output "redis_primary_key" {
  description = "The primary access key for the Redis Cache instance"
  value       = azurerm_redis_cache.main_cache.primary_access_key
  sensitive   = true
}

output "redis_primary_connection_string" {
  description = "The primary connection string for the Redis Cache instance"
  value       = azurerm_redis_cache.main_cache.primary_connection_string
  sensitive   = true
}
 
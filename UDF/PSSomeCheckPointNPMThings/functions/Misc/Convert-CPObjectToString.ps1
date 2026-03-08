function Convert-CPObjectToString {
    Param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )
    switch ($InputObject.type) {
        "network" {
            return $InputObject.subnet4 + "/" + $InputObject."mask-length4"
        }
        "host" {
            return $InputObject."ipv4-address"
        }
        "address-range" {
            return $InputObject."ipv4-address-first" + "-" + $InputObject."ipv4-address-last"
        }
        "simple-gateway" {
            return $InputObject."ipv4-address"
        }
        "dns-domain" {
            return $InputObject.name.Substring(1)
        }
        "checkpoint-host" {
            return $InputObject."ipv4-address"
        }
        default {
            throw "Object not supported"
        }
    }
}

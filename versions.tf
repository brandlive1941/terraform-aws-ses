terraform {
  required_version = ">= 1.5.7"

  required_providers {
    # 6.x for `data.aws_region.region`; `.name` is deprecated there.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

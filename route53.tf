#Set the domain name
resource "aws_route53_zone" "ph_hostedzone" {
  name = "slpowerhouse.com"
}

#Create a record
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.ph_hostedzone.zone_id
  name    = "slpowerhouse.com"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}


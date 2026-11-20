## Unreleased

IMPROVEMENTS:

* Access logging can now be enabled via the new `access_logs` variable
* Zonal shift can now be enabled via the new `enable_zonal_shift` variable

BACKWARDS INCOMPATIBILITIES / NOTES:

* The AWS provider must now be v5.89 or higher, the first version supporting
  zonal shift on Application Load Balancers. Support for v3, v4 and v5 below
  5.89 is dropped.

## 4.0.0 (Dec 28th, 2022)

IMPROVEMENTS:

* SSL policy is now configurable
* AWS provider v4 is now allowed

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 1.0 and higher.

## 3.0.0 (May 27th, 2021)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 0.14 and higher.

## 0.1.4 (September 9th, 2017) 

IMPROVEMENTS:

* The zone ID and the DNS name of the ELB are now output from the module.   

# S3 Express One Zone Bucket Name Validation

## Regex Pattern
```regex
^(?!xn--|sthree-|sthree-configurator|amzn-s3-demo-)[a-z0-9][a-z0-9-]{1,45}[a-z0-9](?<!-s3alias|--ol-s3|\.mrap)$
```

## Pattern Breakdown

### 1. Negative Lookahead for Forbidden Prefixes
```regex
(?!xn--|sthree-|sthree-configurator|amzn-s3-demo-)
```
- `(?!...)` - Negative lookahead assertion
- Rejects names starting with:
  - `xn--`
  - `sthree-`
  - `sthree-configurator`
  - `amzn-s3-demo-`

### 2. Start Character
```regex
[a-z0-9]
```
- Must begin with a lowercase letter or number

### 3. Middle Characters
```regex
[a-z0-9-]{1,45}
```
- 1 to 45 characters of lowercase letters, numbers, or hyphens
- This allows for the base name to be 3-47 characters total (start + middle + end)
- When combined with `--{zone}--x-s3` suffix, stays within 63 character limit

### 4. End Character
```regex
[a-z0-9]
```
- Must end with a lowercase letter or number

### 5. Negative Lookbehind for Forbidden Suffixes
```regex
(?<!-s3alias|--ol-s3|\.mrap)
```
- `(?<!...)` - Negative lookbehind assertion
- Rejects names ending with:
  - `-s3alias`
  - `--ol-s3`
  - `.mrap`

## Full Bucket Name Construction

The CloudFormation template constructs the final bucket name as:
```
{BucketName}--{AvailabilityZone}--x-s3
```

Example:
- Input: `resource-monitor-data`
- Availability Zone: `us-east-1a`
- Final bucket name: `resource-monitor-data--us-east-1a--x-s3`

## Length Calculation

- Minimum base name: 3 characters
- Maximum base name: 47 characters
- Suffix length: `--{zone}--x-s3` = ~16 characters (varies by zone)
- Total maximum: 47 + 16 = 63 characters (AWS S3 limit)

## Valid Examples
✅ `my-app` → `my-app--us-east-1a--x-s3`
✅ `data123` → `data123--us-west-2b--x-s3`
✅ `resource-monitor-data` → `resource-monitor-data--eu-west-1c--x-s3`

## Invalid Examples
❌ `xn--test` (forbidden prefix)
❌ `sthree-bucket` (forbidden prefix)
❌ `test-s3alias` (forbidden suffix)
❌ `my--ol-s3` (forbidden suffix)
❌ `ab` (too short)
❌ `Test-Bucket` (uppercase letters)
❌ `-test` (starts with hyphen)
❌ `test-` (ends with hyphen)

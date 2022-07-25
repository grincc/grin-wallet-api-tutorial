<?php
require_once __DIR__ . "/bech32.php";
require_once __DIR__ . "/base32.php";

use Base32\Base32;

$arguments = getopt("a:");
$wallet = $arguments["a"];

// let's find the public key...
$data = decodeRaw($wallet)[1]; // bech32 decode
$decoded = convertBits($data, count($data), 5, 8, false);
$pkb = pack("C*", ...$decoded); // binary public key
// let's get the checksum
$checksum = hash("sha3-256", b".onion checksum" . $pkb . "\x03", true);
$u = unpack("C*", $checksum);
$cut = $checksum[0] . $checksum[1]; // cut a bit...
$wallet = strtolower(Base32::encode($pkb . $cut . "\x03")); // money!
if (strlen($wallet) === 56) {
    $wallet = "http://{$wallet}.onion";
}

$address = "{$wallet}/v2/foreign";

echo $address;
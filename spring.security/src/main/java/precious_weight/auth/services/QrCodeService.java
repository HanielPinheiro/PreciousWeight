package precious_weight.auth.services;

import org.springframework.stereotype.Service;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

// We implement Version 1 - Level L in this example -> https://www.thonky.com/qr-code-tutorial/introduction
// Version 1-L: total data codewords = 19 (bytes), error correction codewords per block = 7
// See Thonky tables for these numbers (character capacities and error-correction table).
@Service
public class QrCodeService {
    private int CorrectionLevel = 2; //(Q by default)
    private int QrCodeLevel = -1;

    private final int[][] BYTE_MODE_CAPACITY = {{17, 14, 11, 7}, {32, 26, 20, 14}, {53, 42, 32, 24}, {78, 62, 46, 34}, {106, 84, 60, 44}, {134, 106, 74, 58}, {154, 122, 86, 64}, {192, 152, 108, 84}, {230, 180, 130, 98}, {271, 213, 151, 119}, {321, 251, 177, 137}, {367, 287, 203, 155}, {425, 331, 241, 177}, {458, 362, 258, 194}, {520, 412, 292, 220}, {586, 450, 322, 250}, {644, 504, 364, 280}, {718, 560, 394, 310}, {792, 624, 442, 338}, {858, 666, 482, 382}, {929, 711, 509, 403}, {1003, 779, 565, 439}, {1091, 857, 611, 461}, {1171, 911, 661, 511}, {1273, 997, 715, 535}, {1367, 1059, 751, 593}, {1465, 1125, 805, 625}, {1528, 1190, 868, 658}, {1628, 1264, 908, 698}, {1732, 1370, 982, 742}, {1840, 1452, 1030, 790}, {1952, 1538, 1112, 842}, {2068, 1628, 1168, 898}, {2188, 1722, 1228, 958}, {2303, 1809, 1283, 983}, {2431, 1911, 1351, 1051}, {2563, 1989, 1423, 1093}, {2699, 2099, 1499, 1139}, {2809, 2213, 1579, 1219}, {2953, 2331, 1663, 1273}};
    private final int[][] Total_Codewords = {{19, 16, 13, 9}, {34, 28, 22, 16}, {55, 44, 34, 26}, {80, 64, 48, 36}, {108, 86, 62, 46}, {136, 108, 76, 60}, {156, 124, 88, 66}, {194, 154, 110, 86}, {232, 182, 132, 100}, {274, 216, 154, 122}, {324, 254, 180, 140}, {370, 290, 206, 158}, {428, 334, 244, 180}, {461, 365, 261, 197}, {523, 415, 295, 223}, {589, 453, 325, 253}, {647, 507, 367, 283}, {721, 563, 397, 313}, {795, 627, 445, 341}, {861, 669, 485, 385}, {932, 714, 512, 406}, {1006, 782, 568, 442}, {1094, 860, 614, 464}, {1174, 914, 664, 514}, {1276, 1000, 718, 538}, {1370, 1062, 754, 596}, {1468, 1128, 808, 628}, {1531, 1193, 871, 661}, {1631, 1267, 911, 701}, {1735, 1373, 985, 745}, {1843, 1455, 1033, 793}, {1955, 1541, 1115, 845}, {2071, 1631, 1171, 901}, {2191, 1725, 1231, 961}, {2306, 1812, 1286, 986}, {2434, 1914, 1354, 1054}, {2566, 1992, 1426, 1096}, {2702, 2102, 1502, 1142}, {2812, 2216, 1582, 1222}, {2956, 2334, 1666, 1276}};
    private final int[][] EC_Codewords_Per_Block = {{7, 10, 13, 17}, {10, 16, 22, 28}, {15, 26, 18, 22}, {20, 18, 26, 16}, {26, 24, 18, 22}, {18, 16, 24, 28}, {20, 18, 18, 26}, {24, 22, 22, 26}, {30, 22, 20, 24}, {18, 26, 24, 28}, {20, 30, 28, 24}, {24, 22, 26, 28}, {26, 22, 24, 22}, {30, 24, 20, 24}, {22, 24, 30, 24}, {24, 28, 24, 30}, {28, 28, 28, 28}, {30, 26, 28, 28}, {28, 26, 26, 26}, {28, 26, 30, 28}, {28, 26, 28, 30}, {28, 28, 30, 24}, {30, 28, 30, 30}, {30, 28, 30, 30}, {26, 28, 30, 30}, {28, 28, 28, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}};
    private final int[][] Number_DataBlocks_Group1 = {{1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 2, 2}, {1, 2, 2, 4}, {1, 2, 2, 2}, {2, 4, 4, 4}, {2, 4, 2, 4}, {2, 2, 4, 4}, {2, 3, 4, 4}, {2, 4, 6, 6}, {4, 1, 4, 3}, {2, 6, 4, 7}, {4, 8, 8, 12}, {3, 4, 11, 11}, {5, 5, 5, 11}, {5, 7, 15, 3}, {1, 10, 1, 2}, {5, 9, 17, 2}, {3, 3, 17, 9}, {3, 3, 15, 15}, {4, 17, 17, 19}, {2, 17, 7, 34}, {4, 4, 11, 16}, {6, 6, 11, 30}, {8, 8, 7, 22}, {10, 19, 28, 33}, {8, 22, 8, 12}, {3, 3, 4, 11}, {7, 21, 1, 19}, {5, 19, 15, 23}, {13, 2, 42, 23}, {17, 10, 10, 19}, {17, 14, 29, 11}, {13, 14, 44, 59}, {12, 12, 39, 22}, {6, 6, 46, 2}, {17, 29, 49, 24}, {4, 13, 48, 42}, {20, 40, 43, 10}, {19, 18, 34, 20}};
    private final int[][] Number_Data_Codewords_In_Blocks_Group1 = {{19, 16, 13, 9}, {34, 28, 22, 16}, {55, 44, 17, 13}, {80, 32, 24, 9}, {108, 43, 15, 11}, {68, 27, 19, 15}, {78, 31, 14, 13}, {97, 38, 18, 14}, {116, 36, 16, 12}, {68, 43, 19, 15}, {81, 50, 22, 12}, {92, 36, 20, 14}, {107, 37, 20, 11}, {115, 40, 16, 12}, {87, 41, 24, 12}, {98, 45, 19, 15}, {107, 46, 22, 14}, {120, 43, 22, 14}, {113, 44, 21, 13}, {107, 41, 24, 15}, {116, 42, 22, 16}, {111, 46, 24, 13}, {121, 47, 24, 15}, {117, 45, 24, 16}, {106, 47, 24, 15}, {114, 46, 22, 16}, {122, 45, 23, 15}, {117, 45, 24, 15}, {116, 45, 23, 15}, {115, 47, 24, 15}, {115, 46, 24, 15}, {115, 46, 24, 15}, {115, 46, 24, 15}, {115, 46, 24, 16}, {121, 47, 24, 15}, {121, 47, 24, 15}, {122, 46, 24, 15}, {122, 46, 24, 15}, {117, 47, 24, 15}, {118, 47, 24, 15}};
    private final int[][] Number_DataBlocks_Group2 = {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 2, 2}, {0, 0, 0, 0}, {0, 0, 4, 1}, {0, 2, 2, 2}, {0, 2, 4, 4}, {2, 1, 2, 2}, {0, 4, 4, 8}, {2, 2, 6, 4}, {0, 1, 4, 4}, {1, 5, 5, 5}, {1, 5, 7, 7}, {1, 3, 2, 13}, {5, 1, 15, 17}, {1, 4, 1, 19}, {4, 11, 4, 16}, {5, 13, 5, 10}, {4, 0, 6, 6}, {7, 0, 16, 0}, {5, 14, 14, 14}, {4, 14, 16, 2}, {4, 13, 22, 13}, {2, 4, 6, 4}, {4, 3, 26, 28}, {10, 23, 31, 31}, {7, 7, 37, 26}, {10, 10, 25, 25}, {3, 29, 1, 28}, {0, 23, 35, 35}, {1, 21, 19, 46}, {6, 23, 7, 1}, {7, 26, 14, 41}, {14, 34, 10, 64}, {4, 14, 10, 46}, {18, 32, 14, 32}, {4, 7, 22, 67}, {6, 31, 34, 61}};
    private final int[][] Number_Data_Codewords_In_Blocks_Group2 = {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 16, 12}, {0, 0, 0, 0}, {0, 0, 15, 14}, {0, 39, 19, 15}, {0, 37, 17, 13}, {69, 44, 20, 16}, {0, 51, 23, 13}, {93, 37, 21, 15}, {0, 38, 21, 12}, {116, 41, 17, 13}, {88, 42, 25, 13}, {99, 46, 20, 16}, {108, 47, 23, 15}, {121, 44, 23, 15}, {114, 45, 22, 14}, {108, 42, 25, 16}, {117, 0, 23, 17}, {112, 0, 25, 0}, {122, 48, 25, 16}, {118, 46, 25, 17}, {107, 48, 25, 16}, {115, 47, 23, 17}, {123, 46, 24, 16}, {118, 46, 25, 16}, {117, 46, 24, 16}, {116, 48, 25, 16}, {116, 47, 25, 16}, {0, 47, 25, 16}, {116, 47, 25, 16}, {116, 47, 25, 17}, {122, 48, 25, 16}, {122, 48, 25, 16}, {123, 47, 25, 16}, {123, 47, 25, 16}, {118, 48, 25, 16}, {119, 48, 25, 16}};
    private final int[] ExponentsOfAlpha = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255};
    private final int[] IntegerValue = {1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, 157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35, 70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161, 95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240, 253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226, 217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206, 129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204, 133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84, 168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115, 230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166, 81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9, 18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22, 44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1};

    // Simple bit buffer helper
    private final List<Integer> bits = new ArrayList<>();

    public Map<String, Object> fromUuid(String myString) throws Exception {
        BuildBitString(myString);

        ErrorCorrectionCoding();

        Map<String, Object> resp = new LinkedHashMap<>();
        return resp;
    }

    private void BuildBitString(String myString) throws Exception {
        bits.clear();

        byte[] strBytes = myString.getBytes(StandardCharsets.UTF_8);
        int strSize = strBytes.length;
        //Determine the QrCode Level based on the Correction Level and message size
        for (int version = 0; version < 40; version++) {
            int capacity = BYTE_MODE_CAPACITY[version][CorrectionLevel];
            if (capacity >= strSize) {
                QrCodeLevel = version;
                break;
            }
        }

        if (QrCodeLevel == -1) throw new Exception("UUID is too large to fit in any QR code version");

        // Step: Build bit string:
        // - Mode(4 bits) +
        // - CharCount(8 or 16 bits, based on qr version) +
        // - data bytes (data converted to ISO 8859-1 or UTF-8, and them each char to byte)
        // - Break Up into 8-bit Codewords and Add Pad Bytes if Necessary:
        // - Add Terminator
        // -- get total codewords using TotalCodewors[QrCodeLevel][CorrectionLevel] and multiply by 8
        // -- if total is 104 (example), and i have <= 100 (total -4), i put only 4 0s at end, even if number was too short than total, example, 70. If i > 100 and < 104, fill with 0s
        // - Add More 0s to Make the Length a Multiple of 8
        // -- After adding the terminator, if the number of bits in the string is not a multiple of 8, first pad the string on the right with 0s to make the string's length a multiple of 8.

        AppendBits(0b0100, 4); // mode indicator for byte mode is 0100 -> Using byte modes because utf-8 compatible
        int lengthSize = QrCodeLevel >= 9 ? 16 : 8; //Version 1-9 (index = 0 to 8) = 8 bits length, others 16 bits
        AppendBits(strSize, lengthSize);

        //Step 3: Encode Using the Selected Mode
        for (byte b : strBytes) AppendBits(b & 0xFF, lengthSize);

        //Step 4: Break Up into 8-bit Codewords and Add Pad Bytes if Necessary
        //Determine the Required Number of Bits for this QR Code
        int TOTAL_DATA_CODEWORDS = Total_Codewords[QrCodeLevel][CorrectionLevel];
        int totalDataBits = TOTAL_DATA_CODEWORDS * 8;
        // Add terminator up to 4 zeros if needed
        int remaining = totalDataBits - GetSize();
        if (remaining > 0) {
            int terminator = Math.min(4, remaining);
            AppendBits(0, terminator);
        }

        // Add More 0s to Make the Length a Multiple of 8
        int actualSize = GetSize();
        if (actualSize % 8 != 0) {
            int nextMultipleOf8 = (actualSize + 7) & (-8);
            AppendBits(0, nextMultipleOf8 - actualSize); // will add 0s until complete the length
        }

        //Add Pad Bytes if the String is Still too Short
        remaining = totalDataBits - GetSize();
        int loops = remaining / 8; //104 - 80 / 8 = 3;
        //00010001 = 17, 11101100 = 236
        if ((remaining & 1) == 0) {
            //if number is 2, run loops once and add 16 bits (236 and 17)
            loops /= 2;
            for (int i = 0; i < loops; i++) AppendBits(0b1110110000010001, 16); //add 236 and 17
        } else {
            //if number is 1, no loop, add 236. Number is 3, remove 1, divide by two, run loop once, add extra pack of 236
            loops -= 1;
            loops /= 2;
            for (int i = 0; i < loops; i++) AppendBits(0b1110110000010001, 16); //add 236 and 17
            AppendBits(0b11101100, 8); // if not multiple of 2, will need a extra pack o 8 bits at end (236)
        }
    }

    private void AppendBits(int val, int length) {
        for (int i = length - 1; i >= 0; i--) {
            bits.add((val >> i) & 1);
        }
    }

    private int GetSize() {
        return bits.size();
    }

    private void MessageIntoBlocks() {
        // Notice that, for a 5-Q code, 15+15+16+16 = 62 codewords of data
        // In this example, there are four blocks of 18 error codewords. Total of 72 error correction codewords.
        //62+72 = 134 total codewords (data + error

        // Step 1: Break Data Codewords into Blocks if Necessary
        // data codewords is 8 bits of data, ex: 00001111
        // it may be necessary to break up the data codewords into smaller blocks if the QR code is larger than version 2
        // split data codewords in two groups, and in blocks inside groups the data are broken up sequentially

        int blocksNum_Group1 = Number_DataBlocks_Group1[QrCodeLevel][CorrectionLevel];
        int totalCodewordsInEachBlock_Group1 = Number_Data_Codewords_In_Blocks_Group1[QrCodeLevel][CorrectionLevel];
        int[][] group1 = ChunkGroupsInBlocks(totalCodewordsInEachBlock_Group1);

        int blocksNum_Group2 = Number_DataBlocks_Group2[QrCodeLevel][CorrectionLevel];
        int totalCodewordsInEachBlock_Group2 = Number_Data_Codewords_In_Blocks_Group2[QrCodeLevel][CorrectionLevel];
        if (blocksNum_Group2 > 0 || totalCodewordsInEachBlock_Group2 > 0) {
            int[][] group2 = ChunkGroupsInBlocks(totalCodewordsInEachBlock_Group2);
        }

    }

    private void ErrorCorrectionCoding() throws Exception {
        int errorCodePerBlock = EC_Codewords_Per_Block[QrCodeLevel][CorrectionLevel];
        /*
          Explanation of theory from https://www.thonky.com/qr-code-tutorial/

        //Polynomial long division
        /**
           Overall, the steps of polynomial long division are:

              Find the appropriate term to multiply the divisor by. The result of the multiplication should have the same first term as the the dividend (in the first multiplication step) or remainder (in all subsequent multiplication steps).
              Subtract the result from the dividend (in the first multiplication step) or remainder (in all subsequent multiplication steps).
              Repeat steps 1 and 2 until it is no longer possible to multiply by an integer, or in other words, it would be necessary to multiply by a fraction. The number at the bottom of the tableau is the remainder.

           The polynomial long division necessary for Reed-Solomon Error Correction is simpler in some ways than this example, because it will not be necessary to deal with the exponents of the polynomial terms.

        // Step 3: Understand The Galois Field
        // To generate error correction codewords, this process uses a method called Reed-Solomon Error correction
        // Along with polynomial long division, this method uses a Galois field (256), which is essentially a restricted set of numbers, as well as some mathematical operations that create numbers that are still in that set.
        //  The numbers in GF(256) will all be in the range of 0 through 255 (inclusive).
        /**
          In the Galois Field, negative numbers have the same value as positive numbers, so -n = n.
          This means that addition and subtraction within the Galois Field are the same thing.
          Addition and subtraction in the Galois Field are performed by doing the addition or subtraction as normal, but then performing the modulo operation.
          And since we are using bit-wise modulo 2 arithmetic (as mentioned in the QR code specification), this is the same as performing the XOR operation.
          1 + 1 = 2. 2 % 2 = 0 -> The same of: 1 XOR(+ or -) 1 = 0
          0 + 1 = 1. 1 % 2 = 1 -> 0 XOR(^) 1 = 1

        //Step 5: Generate Powers of 2 using Byte-Wise Modulo 100011101
        /**
          All of the numbers in GF(256) can be represented as a power of 2.
          Specifically, all numbers in GF(256) can be represented as 2n, where 0 <= n <= 255.
          2 power 8 would seem to be too big for the Galois Field since it is equal to 256.
          The QR code specification says to use byte-wise modulo 100011101 arithmetic
          (where 100011101 is a binary number that is equivalent to 285 in decimal).
          This means that when a number is 256 or larger, it should be XORed with 285.
          This leads to unexpected values for 2 power 8 and larger.
          28 = 256. 256 > 255. 256 ^(XORed) 285 = 29
          When continuing on to 2 power 9, do not take its usual value of 512 and XOR with 285
          (which would result in too large a number anyway). Do it: 2 power 9 = 2 power 8 * 2.
          2 power 9 = 2 power 8 * 2 -> 29 (equivalent to 256 ^(XORed) 285) * 2 = 58
          Continue using the previous power of 2 to create the next powers of 2:
          2 power 10 = 2 power 9 * 2 = 58 * 2 = 116
          2 power11 = 2 power 10 * 2 = 116 * 2 = 232
          Whenever a value greater than or equal to 256 is obtained, once again XOR with 285:
          2 power 12 = 2 power 11 * 2 = 232 * 2 = 464. 464 >255 -> 464 ^ 285 = 205
          In general, the values are always equal to 2 times the previous power, and if that value is 256 or greater, it is XORed with 285.


        //Step 6: Understand Multiplication with Logs and Antilogs
        /**
          Because all of the values can be represented with 2n as explained above,
          it is possible to logs and antilogs to simplify multiplication in GF(256).
          one can multiply two numbers p and q with the following operation: b power (logb p + logb q)
          In this case, base 2 is in use, so the above operation becomes 2 power (log2 p + log2 q)
          The log2 x operation tells us how many times to multiply 2 to get an answer of x.
          In other words, it determines n where 2 power n = x. n = log2 p + log2 q
          This provides a shortcut for multiplying numbers in GF(256): 2 pow 2 * 2 pow 8 = 2 pow (2 + 8) = 2 pow 10
          And by this, we can discover all values of numbers in GF(256), based on Bitwise Modulo rule


        //Step 7: Understanding The Generator Polynomial
        /**
          As mentioned earlier, error correction coding uses polynomial long division.
          To do that, two polynomials are needed. The first polynomial to use is called
          the message polynomial.Uses the data codewords from the data encoding step as
          its coefficients.
          If the data codewords, converted to integers, were 25, 218, and 35,
          message polynomial would be 25x2 + 218x + 35.
          The message polynomial will be divided by a GeneratorPolynomial.
          The generator polynomial is a polynomial that is created by multiplying
          (x - ɑ0) ... (x - ɑn-1) where n is the number of error correction codewords
          that must be generated. (alpha) is equal to 2.
          So, need a function to generate dividend polynomial from a block in alpha notation
          Need a function to generate divisorpolynomial to divide based in value of error code per block
          NeededPolynomial = Dividend / Divisor;
          ****When we multiply two alpha values, normally we add the two exponents together.
          But if the result is bigger than 255, we have a problem.
          To prevent that we put the resulting exponent through the following formula:
                        (exponent % 256) + floor(exponent / 256)
          ****When adding terms in base of X during the creation of a generator polynomial,
          you must always XOR the integers rather than adding them.
         */
        var message_array = GenerateDividend_MessagePolynomial();
        var generator_array = GenerateDivisor_GeneratorPolynomial(errorCodePerBlock);
        var result1 = dividePolynomials(message_array, generator_array);
    }

    private int[] dividePolynomials(int[] message_array, int[] generator_array) throws Exception {
        //Generator is alpha based, message is integer based
        /*
        System.out.println(Arrays.toString(message_array));
        System.out.printf("Error code: %d bytes %n", errorCodePerBlock);
        System.out.println(Arrays.toString(generator_array));
        //*/
        /*
        Now it is time to divide the message polynomial by the generator polynomial.
        //change both arr size to errCodePerBlock + MessagePolynomial.Length
        //The number of steps in the division must equal the number of terms in the message polynomial
        //The remainders of division will be the terms of correction codewords
        */

        int divSteps = message_array.length;
        int errorElements = generator_array.length;
        int newOrder = divSteps + errorElements;
        int[] messageWithNewSize = new int[newOrder];
        System.arraycopy(message_array, 0, messageWithNewSize, errorElements, message_array.length);
        int[] generatorWithNewSize = new int[newOrder];
        System.arraycopy(generator_array, 0, generatorWithNewSize, divSteps, generator_array.length);

        for (int step = newOrder - 1; step > 0; step--) {
            int leadTerm = messageWithNewSize[step];
            if (leadTerm != 0) {
                // Convert leadTerm to alpha exponent
                int leadAlpha = GetAlphaFromIntegerBaseX(leadTerm);
                // Multiply generator polynomial by lead term in alpha notation

                Faz sentido o array ser crescente aqui ?
                for (int counter = 0; counter < newOrder; counter++) {
                    if (generatorWithNewSize[counter] != 0) {
                        int newAlphaValue = FixExponentUsingFormula(generatorWithNewSize[counter], leadAlpha);
                        int newIntegerValue = GetIntegerBaseXFromAlpha(newAlphaValue);
                        System.out.printf("OldAlpha:{%d}, New Alpha:{%d}, New Integer:{%d}%n", generatorWithNewSize[counter], newAlphaValue, newIntegerValue);
                        generatorWithNewSize[counter] = newIntegerValue;
                    }
                }
            }
//            // The remainder (last errorCodePerBlock terms) is the ECC
//            int[] remainder = new int[errorCodePerBlock];
//            System.arraycopy(working, working.length - errorCodePerBlock, remainder, 0, errorCodePerBlock);
//            System.out.printf("Remainder: {");
//            for (int counter = 0; counter < errorCodePerBlock; counter++)
//                System.out.printf("%d,", remainder[counter]);
//            System.out.printf("}%n");
//            return remainder;

            //Now generator and message are in integer notation
            //Step 1b: XOR the result with the message polynomial
            int[] result = new int[newOrder];
            for (int counter = 0; counter < newOrder; counter++) {
                result[counter] = generatorWithNewSize[counter] ^ messageWithNewSize[counter];
            }
            // now loop until complete the division steps
        }
        return new int[]{0};
    }

    private int[][] ChunkGroupsInBlocks(int dataCodewordsInBlocks) {
        int totalBlocks = GetSize() / dataCodewordsInBlocks;
        int[][] group = new int[totalBlocks][dataCodewordsInBlocks];

        int blockCounter = 0;
        for (int i = 0; i < GetSize(); i += dataCodewordsInBlocks) {
            int codewordCounter = 0;
            int endIndex = Math.min(i + dataCodewordsInBlocks, GetSize());
            for (int j = i; j < endIndex; j++) {
                group[blockCounter][codewordCounter] = bits.get(j);
                codewordCounter++;
            }
        }
        return group;
    }

    private int[] GenerateDividend_MessagePolynomial() {
        boolean printDecimal = false;
        List<List<Integer>> chunks = IntStream.range(0, (bits.size() + 7) / 8).
                mapToObj(i -> bits.subList(i * 8, Math.min((i + 1) * 8, bits.size()))).
                toList();

        int[] coefficients = new int[chunks.size()];

        for (int i = 0; i < chunks.size(); i++) {
            List<Integer> chunk = chunks.get(i);
            int decimal = 0;
            int decimalToPrint = 0;

            // Convert binary list to decimal
            for (int j = 0; j < 8; j++) {
                decimal = (decimal << 1) | chunk.get(j);
                if (printDecimal) decimalToPrint += chunk.get(j) * (1 << (7 - j));
            }
            if (printDecimal) {
                char ascii = decimalToPrint < 32 || decimalToPrint > 126 ? ' ' : (char) decimalToPrint;
                System.out.printf("%5d | %s | %7d | %s%n", i + 1, chunk.toString().replace(" ", ""), decimalToPrint, ascii == ' ' ? "(Non-printable)" : "'" + ascii + "'");
            }
            coefficients[i] = decimal;
        }
        return coefficients;
    }

    private int[] GenerateDivisor_GeneratorPolynomial(int polynomial_size) throws Exception {
        if (polynomial_size <= 2) throw new Exception("Invalid!");

        int[] new_polynomial = new int[3]; //new_pol[4] if size = 3, because x pow 0 or constant
        new_polynomial[0] = 1; //ɑ¹x0 -> x[0]= alpha 1, arr index  = x exponent
        new_polynomial[1] = 25; //ɑ25x¹ -> x[1]= alpha 25, arr value = alpha exponent
        new_polynomial[2] = 0; //ɑ0x² -> x[2]= alpha 0

        for (int pol_degree = 2; pol_degree < polynomial_size; pol_degree++) {
            int[] new_term = new int[]{pol_degree, 0};  //always have two components, alpha(0)x¹ - alpha(exponent)x0
            new_polynomial = ComputePolynomialMultiplication(new_polynomial, new_term);
        }
        return new_polynomial;
    }

    private int[] ComputePolynomialMultiplication(int[] old_polynomial, int[] new_term) throws Exception {
        int old_polynomial_size = old_polynomial.length;
        int new_term_size = new_term.length;
        int[] new_polynomial = new int[old_polynomial_size + new_term_size - 1];
        Arrays.fill(new_polynomial, -1);

        for (int i = 1; i <= old_polynomial_size; i++) {
            for (int j = 1; j <= new_term_size; j++) {
                int polynomial_idx = old_polynomial_size - i; //2-1=1;
                int new_term_idx = new_term_size - j; //3-1=2;

                //If there are any exponents that are larger than 255, fix them by putting them through the formula
                int alpha_exponent = FixExponentUsingFormula(new_term[new_term_idx], old_polynomial[polynomial_idx]);
                int new_pol_x_exponent = FixExponentUsingFormula(new_term_idx, polynomial_idx);

                if (new_polynomial[new_pol_x_exponent] != -1) {
                    //Combine terms -> Convert alphas to integer and xor them
                    int old_alpha_value_in_x_notation = GetIntegerBaseXFromAlpha(new_polynomial[new_pol_x_exponent]);
                    int new_alpha_value_in_x_notation = GetIntegerBaseXFromAlpha(alpha_exponent);
                    int new_alpha_exponent = old_alpha_value_in_x_notation ^ new_alpha_value_in_x_notation;
                    new_polynomial[new_pol_x_exponent] = GetAlphaFromIntegerBaseX(new_alpha_exponent);
                } else new_polynomial[new_pol_x_exponent] = alpha_exponent;
            }
        }
        return new_polynomial;
    }

    private int FixExponentUsingFormula(int a, int b) {
        int result = a + b;
        if (result > 255) result = (result % 256) + (int) Math.floor(result / 256);
        return result;
    }

    private int GetAlphaFromIntegerBaseX(int integer) throws Exception {
        int size = IntegerValue.length;
        int tgt = -1;
        for (int i = 0; i < size; i++) {
            if (IntegerValue[i] == integer) {
                tgt = ExponentsOfAlpha[i];
                break;
            }
        }
        if (tgt == -1) throw new Exception("Not found");
        return tgt;
    }

    private int GetIntegerBaseXFromAlpha(int exponent) throws Exception {
        int size = ExponentsOfAlpha.length;
        int tgt = -1;
        for (int i = 0; i < size; i++) {
            if (ExponentsOfAlpha[i] == exponent) {
                tgt = IntegerValue[i];
                break;
            }
        }
        if (tgt == -1) throw new Exception("Not found");
        return tgt;
    }


}

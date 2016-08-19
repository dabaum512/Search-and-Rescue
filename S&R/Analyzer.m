//
//  Analyzer.m
//  SR1
//
//  Created by Justin Moser on 6/20/14.
//  Copyright (c) 2014 Justin Moser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <arm_neon.h>
#import "Analyzer.h"
#import "Header.h"

#define THRESHOLD 240*3

uint8x16_t zero = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
uint8x16_t ones = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
uint8x16_t hundred = {0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64,0x64};
uint8x16_t k120 = {0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78};

@interface Analyzer() {
    int i,k,a;
    int d;
    long int row_mx, total_row_mx,total_row_mass;
    float final_X;
    float final_Y;
    float m1;
    float m2;
    int row_mass;
    
    //bright spot
    uint8x16_t vBlue,vGreen,vRed,vAdd1,vAdd2;
    uint8x16x4_t v8x16x4;
    
    //red spot
    uint8x16_t blueGreen;
    uint8x16_t halfRed;
    uint8x16_t check1;
    uint8x16_t check2;
    uint8x16_t check3;
    uint8x16_t check4;
    uint8x16_t check5;
    uint8x8x2_t noiseCheck;
    uint8x8_t final;
    
    const unsigned char *red;
    const unsigned char *green;
    const unsigned char *blue;
}

@end


@implementation Analyzer

#pragma mark - Regular Methods

-(CGPoint)brightSpotFromBuffer:(unsigned char *)buffer rows:(size_t)rows cols:(size_t)cols {
//    const unsigned char *buffer = data.bytes;
    
    double totalMass = 0;
    double totalX = 0;
    double totalY = 0;
    double change = 0;
    double yy = 0;
    
    int ii = 0, kk = 0;
    uint8_t rred, bblue, ggreen;
    
    printf("test\n");
    
    for (; ii < rows; ii += 4) {
        for (; kk < cols; kk += 4) {
            
            rred = buffer[4 * (ii * cols + kk) + 0];
            ggreen = buffer[4 * (ii * cols + kk) + 1];
            bblue = buffer[4 * (ii * cols + kk) + 2];
            
            
            
            if (change > THRESHOLD) {
                totalMass += change;
                totalX += change * (kk + 0.5);
                yy += change;
            }
        }
        totalY += yy * (ii + 0.5);
        yy = 0;
        kk = 0;
    }
    
    if (totalMass > 0) {
        return CGPointMake((totalX / totalMass) / cols, (totalY / totalMass) / rows);
    } else {
        return CGPointMake(-1, -1);
    }
}

CGPoint brightSpotFromBuffer(const unsigned char *buffer, size_t rows, size_t cols) {
    double totalMass = 0;
    double totalX = 0;
    double totalY = 0;
    double change = 0;
    double yy = 0;
    
    int i = 0, k = 0;
    uint8_t red, blue, green;
    
    for (; i < rows; i += 4) {
        for (; k < cols; k += 4) {
            
            red = buffer[4 * (i * cols + k) + 0];
            green = buffer[4 * (i * cols + k) + 1];
            blue = buffer[4 * (i * cols + k) + 2];
            
            change = red + green + blue;
            
            if (change > THRESHOLD) {
                totalMass += change;
                totalX += change * (k + 0.5);
                yy += change;
            }
        }
        
        totalY += yy * (i + 0.5);
        yy = 0;
        k = 0;
    }
    
    if (totalMass > 0) {
        return CGPointMake((totalX / totalMass) / cols, (totalY / totalMass) / rows);
    } else {
        return CGPointMake(-1, -1);
    }
}

CGPoint brightSpotFromLuma(const unsigned char *buffer, size_t rows, size_t cols) {
    
    size_t blocks = 8;
    
    double *_totalMass = malloc(blocks * sizeof(double));
    double *_totalX = malloc(blocks * sizeof(double));
    double *_totalY = malloc(blocks * sizeof(double));
    
    int rowAmount = (int)rows / blocks;
    
    dispatch_apply(blocks, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t index) {
        uint8_t brightness;
        double iTotalMass, iTotalX, iTotalY;
        
        int minRow = (int)index * rowAmount;
        int maxRow = minRow + rowAmount;
        
        for (int i = minRow; i < maxRow; i++) {
            for (int k = 0; k < cols; k++) {
                
                brightness = buffer[i * cols + k];
                
                if (brightness > 200) {
                    iTotalMass += brightness;
                    iTotalX += brightness * (k + 0.5);
                    iTotalY += brightness * (i + 0.5);
                }
            }
        }

        *(_totalMass + index) = iTotalMass;
        *(_totalX + index) = iTotalX;
        *(_totalY + index) = iTotalY;
    });

    
    double totalMass = 0;
    double totalX = 0;
    double totalY = 0;
    
    for (int i = 0; i < blocks; i++) {
        totalMass += *(_totalMass + i);
        totalX += *(_totalX + i);
        totalY += *(_totalY + i);
    }
    
    free(_totalMass);
    free(_totalX);
    free(_totalY);
    
//    for (int i = 0; i < rows; i++) {
//        for (int k = 0; k < cols; k++) {
//            
//            brightness = buffer[i * cols + k];
//            
//            if (brightness > 170) {
//                totalMass += brightness;
//                totalX += brightness * (k + 0.5);
//                totalY += brightness * (i + 0.5);
//            }
//        }
//    }
    
    if (totalMass > 0) {
        return CGPointMake((totalX / totalMass) / cols, (totalY / totalMass) / rows);
    } else {
        return CGPointMake(-1, -1);
    }
}

-(CGPoint)redSpotFromBuffer:(const unsigned char *)buffer rows:(size_t)rows coloumns:(size_t)cols {
    i = k = d = row_mx = total_row_mx = total_row_mass = 0;
    final_X = final_Y = m1 = m2 = 0.0;
    
    
    for (i = 0; i < rows; i+=1) {
        for (k = 0; k < cols*4 ; k += 4) {
            
            red = &buffer[i * cols * 4 + k + 2];
            green = &buffer[i * cols * 4 + k + 1];
            blue = &buffer[i * cols * 4 + k + 0];
            
            if ((*red) > 2 * (*green) && (*red) > 2 * (*blue)) {
                if ((*red) > 100 || ((*blue) > (*green) && (*red) > 70)) {
                    
                    m1 += k/4;
                    row_mass += 1;
                }
            }
        }
        if (row_mass > 0) {
            m1 /= row_mass;
            d += 1;
        }
        m2 += m1;
        row_mx = row_mass * i;
        total_row_mx += row_mx;
        total_row_mass += row_mass;
        row_mass = m1 = row_mx = 0;
    }
    final_X = m2 / d;
    final_Y = total_row_mx / total_row_mass;
    
    if (final_X != final_X) {
        final_X = -1;
    }
    if (final_Y != final_Y) {
        final_Y = -1;
    }
    return CGPointMake(final_X, final_Y);
}

-(CGPoint)fastRedSpotFromBuffer:(const unsigned char *)buffer rows:(size_t)rows coloumns:(size_t)cols {
    i = k = d = row_mx = total_row_mx = total_row_mass = 0;
    final_X = final_Y = m1 = m2 = 0.0;
    
    for (i = 0; i < rows - 1; i += 2) {
        for (k = 0; k < cols*4 - 4; k += 8) {
    
            red = &buffer[i * cols * 4 + k + 2];
            green = &buffer[i * cols * 4 + k + 1];
            blue = &buffer[i * cols * 4 + k + 0];
            
            if ((*red) > 2 * (*green) && (*red) > 2 * (*blue)) {
                if ((*red) > 100 || ((*blue) > (*green) && (*red) > 70)) {
                    
                    m1 += k/4;
                    row_mass += 1;
                }
            }
        }
        if (row_mass > 0) {
            m1 /= row_mass;
            d += 1;
        }
        m2 += m1;
        row_mx = row_mass * i;
        total_row_mx += row_mx;
        total_row_mass += row_mass;
        row_mass = m1 = row_mx = 0;
    }
    final_X = m2 / d;
    final_Y = total_row_mx / total_row_mass;
    
    if (final_X != final_X) {
        final_X = -1;
    }
    if (final_Y != final_Y) {
        final_Y = -1;
    }
    return CGPointMake(final_X, final_Y);
}

#pragma mark - Vector Methods

-(CGPoint)vectorRedSpotFromBuffer:(unsigned char * restrict)buffer rows:(size_t)rows coloumns:(size_t)cols {
    d = row_mx = total_row_mx = total_row_mass = 0;
    final_X = final_Y = m1 = m2 = 0.0;
    
    for (i = 0; i < rows - 3; i += 4) {
        for (k = 0; k < cols*4 - 64; k += 64) {
            a = 0;
            
            v8x16x4 = vld4q_u8(buffer + i * cols * 4 + k);
            halfRed = vrshrq_n_u8(v8x16x4.val[2], 1);              // divide red by two
            check1 = vcgeq_u8(halfRed, v8x16x4.val[0]);            // red is atleast twice as large as blue
            check2 = vcgeq_u8(halfRed, v8x16x4.val[1]);            // red is atleast twice as large as green
            check3 = vandq_u8(check1, check2);                     // check
            check4 = vcgeq_u8(v8x16x4.val[2], k120);               // red is greater than 120
            check5 = vandq_u8(check3, check4);                     // check
            blueGreen = vcgtq_u8(v8x16x4.val[0], v8x16x4.val[1]);  // blue greater than green
            check5 = vandq_u8(blueGreen, check5);                  // check
            noiseCheck = vld2_u8((unsigned char *)&check5);        // neighboring pixels are both red (trying to eliminate noise)
            final = vand_u8(noiseCheck.val[0], noiseCheck.val[1]); // check
     
            if (final[0] > 0) {
                
                a += k;
                row_mass += 1;
            }
            if (final[1] > 0) {
                
                a += k + 8;
                row_mass += 1;
            }
            if (final[2] > 0) {
                
                a += k + 16;
                row_mass += 1;
            }
            if (final[3] > 0) {
                
                a += k + 24;
                row_mass += 1;
            }
            if (final[4] > 0) {
                
                a += k + 32;
                row_mass += 1;
            }
            if (final[5] > 0) {
                
                a += k + 40;
                row_mass += 1;
            }
            if (final[6] > 0) {
                
                a += k + 48;
                row_mass += 1;
            }
            if (final[7] > 0) {
                
                a += k + 56;
                row_mass += 1;
            }
           
            a /= 4;
            m1 += a;
        }
        if (row_mass > 0) {
            m1 /= row_mass;
            d += 1;
        }
        m2 += m1;
        row_mx = row_mass * i;
        total_row_mx += row_mx;
        total_row_mass += row_mass;
        row_mass = m1 = row_mx = 0;
    }
    if (d > 0) {
        final_X = m2 / d;
        final_Y = total_row_mx / total_row_mass;
        
        final_X /= cols;
        final_Y /= rows;
    } else {
        final_X = -1;
        final_Y = -1;
    }
    
    return CGPointMake(final_X, final_Y);
}

-(CGPoint)vectorBrightSpotFromBuffer:(unsigned char *)buffer rows:(size_t)rows coloumns:(size_t)cols {
    d = row_mx = total_row_mx = total_row_mass = 0;
    final_X = final_Y = m1 = m2 = 0.0;
    
    for (i = 0; i < rows - 3; i += 4) {
        for (k = 0; k < cols*4 - 64; k += 64) {
            a = 0;
            
            v8x16x4 = vld4q_u8(buffer + i * cols * 4 + k);
            vBlue = vrshrq_n_u8(v8x16x4.val[0], 2);
            vGreen = vrshrq_n_u8(v8x16x4.val[1], 2);
            vRed = vrshrq_n_u8(v8x16x4.val[2], 2);
            
            vAdd1 = vaddq_u8(vBlue, vGreen);
            vAdd2 = vaddq_u8(vAdd1,vRed);
            

            if (vAdd2[0] > 180) {
                
                a += k;
                row_mass += 1;
            }
            if (vAdd2[1] > 180) {
                
                a += k + 4;
                row_mass += 1;
            }
            if (vAdd2[2] > 180) {
                
                a += k + 8;
                row_mass += 1;
            }
            if (vAdd2[3] > 180) {
                
                a += k + 12;
                row_mass += 1;
            }
            if (vAdd2[4] > 180) {
                
                a += k + 16;
                row_mass += 1;
            }
            if (vAdd2[5] > 180) {
                
                a += k + 20;
                row_mass += 1;
            }
            if (vAdd2[6] > 180) {
                
                a += k + 24;
                row_mass += 1;
            }
            if (vAdd2[7] > 180) {
                
                a += k + 28;
                row_mass += 1;
            }
            if (vAdd2[8] > 180) {
                
                a += k + 32;
                row_mass += 1;
            }
            if (vAdd2[9] > 180) {
                
                a += k + 36;
                row_mass += 1;
            }
            if (vAdd2[10] > 180) {
                
                a += k + 40;
                row_mass += 1;
            }
            if (vAdd2[11] > 180) {
                
                a += k + 44;
                row_mass += 1;
            }
            if (vAdd2[12] > 180) {
                
                a += k + 48;
                row_mass += 1;
            }
            if (vAdd2[13] > 180) {
                
                a += k + 52;
                row_mass += 1;
            }
            if (vAdd2[14] > 180) {
                
                a += k + 56;
                row_mass += 1;
            }
            if (vAdd2[15] > 180) {
                
                a += k + 60;
                row_mass += 1;
            }
            
            a /= 4;
            m1 += a;
        }
        if (row_mass > 0) {
            m1 /= row_mass;
            d += 1;
        }
        m2 += m1;
        row_mx = row_mass * i;
        total_row_mx += row_mx;
        total_row_mass += row_mass;
        row_mass = m1 = row_mx = 0;
    }
    final_X = m2 / d;
    final_Y = total_row_mx / total_row_mass;
    
    if (final_X != final_X) {
        final_X = -1;
    }
    if (final_Y != final_Y) {
        final_Y = -1;
    }
    final_X /= cols;
    final_Y /= rows;
    return CGPointMake(final_X, final_Y);
}


@end







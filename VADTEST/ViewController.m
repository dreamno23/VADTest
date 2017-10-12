//
//  ViewController.m
//  VADTEST
//
//  Created by zhangyu on 2017/10/11.
//  Copyright © 2017年 Michong. All rights reserved.
//

#import "ViewController.h"
#import "AEUtils.h"

@interface ViewController ()

@end

@implementation ViewController {
    AEUtils *utls_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    utls_ = [[AEUtils alloc]init];
    [utls_ start];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

//
//  ViewController.m
//  KVOObjectiveC
//
//  Created by Ju on 2020/3/15.
//  Copyright © 2020 Ju. All rights reserved.
//

#import "ViewController.h"
#import "Account.h"
#import "objc/runtime.h"

// Apple 文档
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html

static void *AccountBalanceContext = @"AccountBalanceContext";

@interface ViewController ()

@property (nonatomic, strong) Account *account;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addButtons];
    [self setObserver];
}

-(void)addButtons{
    
    UIButton *change = [UIButton buttonWithType:UIButtonTypeCustom];
    change.frame = CGRectMake(100, 100, 100, 100);
    [change setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [change setTitle:@"Update" forState:UIControlStateNormal];
    [change addTarget:self action:@selector(changeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:change];
    
    UIButton *remove = [UIButton buttonWithType:UIButtonTypeCustom];
    remove.frame = CGRectMake(100, 200, 100, 100);
    [remove setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [remove setTitle:@"Remove" forState:UIControlStateNormal];
    [remove addTarget:self action:@selector(removeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:remove];

}

/*
 调用removeObserver: 方法会把 account 的isa指针重置
 */
- (void)removeAction {
    NSLog(@"Before remove observer class() = %@, objc_getClass = %@", [self.account class], object_getClass(self.account));
    [self.account removeObserver:self forKeyPath:@"balance" context:AccountBalanceContext];
    NSLog(@"After remove observer class() = %@, objc_getClass = %@", [self.account class], object_getClass(self.account));
}

- (void)changeAction {
    NSLog(@"\n点击了Btn!");
    int randomPrice = arc4random() % 100;
    NSString *newPrice = [NSString stringWithFormat:@"%ld",(long)randomPrice];
    
 
    // 下面3个方法都是OK的
    // 1
//    [self.account setValue:newPrice forKey:@"balance"];
//
//    // 2
//    [self.account setValue:newPrice forKeyPath:@"balance"];
//
//    // 3
    self.account.balance = newPrice;
}


- (void)setObserver {
    self.account = [[Account alloc] init];
    self.account.balance = @"100";
    NSLog(@"Before set observer class() = %@, objc_getClass = %@", [self.account class], object_getClass(self.account));
    
    [self.account addObserver:self forKeyPath:@"balance" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:AccountBalanceContext];
    
    // 改变的原因是修改了 isa 指针。开始 class()的实现其实就是object_getClass()
    // runtime创建了一个临时子类， 并且重写了 setBalance(), class()
    NSLog(@"After set observer class() = %@, objc_getClass = %@", [self.account class], object_getClass(self.account));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AccountBalanceContext) {
        NSLog(@"old balance = %@", [change objectForKey:@"old"]);
        NSLog(@"new balance = %@", [change objectForKey:@"new"]);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    /*
     Asking to be removed as an observer if not already registered as one results in an NSRangeException. You either call removeObserver:forKeyPath:context: exactly once for the corresponding call to addObserver:forKeyPath:options:context:, or if that is not feasible in your app, place the removeObserver:forKeyPath:context: call inside a try/catch block to process the potential exception.
     An observer does not automatically remove itself when deallocated. The observed object continues to send notifications, oblivious to the state of the observer. However, a change notification, like any other message, sent to a released object, triggers a memory access exception. You therefore ensure that observers remove themselves before disappearing from memory.
     The protocol offers no way to ask an object if it is an observer or being observed. Construct your code to avoid release related errors. A typical pattern is to register as an observer during the observer’s initialization (for example in init or viewDidLoad) and unregister during deallocation (usually in dealloc), ensuring properly paired and ordered add and remove messages, and that the observer is unregistered before it is freed from memory.
     */
    [self.account removeObserver:self forKeyPath:@"balance" context:AccountBalanceContext];
}

@end

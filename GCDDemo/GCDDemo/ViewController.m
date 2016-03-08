//
//  ViewController.m
//  GCDDemo
//
//  Created by mac on 16/3/5.
//  Copyright © 2016年 dongdong. All rights reserved.
//

#import "ViewController.h"



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self creatDispatchQueue];
//    [self dispatchGroup];
//    [self dispatchBarrierAsync];
    [self dispatchSync];
}
- (void)creatDispatchQueue{
    //Serial Dispatch Queue的使用场景一般是在处理数据竞争类似的问题
    // Serial Dispatch Queue 虽然是串行队列，但是可以创建多个，然后将执行添加到多个Serial Dispatch Queue中，其执行方式是并发的
    // 第一个参数:队列的标识，---该参数也可以是NULL，但是建议使用程序ID因为在调试和CrashLog中可以方便识别
    //第二个参数:队列的类型(串行/并行) ---可以是NULL那么就是串行 NULL = DISPATCH_QUEUE_SERIAL / DISPATCH_QUEUE_CONCURRENT(并行)
    dispatch_queue_t OneserialDispatchQueue = dispatch_queue_create(NULL, NULL);
    dispatch_queue_t concurrentDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t TwoserialDispatchQueue = dispatch_queue_create("TwoserialDispatchQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t ThreeserialDispatchQueue = dispatch_queue_create("ThreeserialDispatchQueue", NULL);
    dispatch_async(OneserialDispatchQueue, ^{
        sleep(2);
        NSLog(@"1=");
    });
    dispatch_async(TwoserialDispatchQueue, ^{
        sleep(2);
        NSLog(@"2=");
    });
    dispatch_async(ThreeserialDispatchQueue, ^{
        sleep(2);
        NSLog(@"3=");
    });
   
    
    dispatch_async(OneserialDispatchQueue, ^{
        sleep(2);
        NSLog(@"4=");
    });
    dispatch_async(concurrentDispatchQueue, ^{
        sleep(2);
        NSLog(@"5=");
    });
    NSLog(@"%@",OneserialDispatchQueue);

    // 执行顺序应该是1、2、3、5三个并发先执行（1、2、3、5的执行顺序可能每次都不一样因为是并发，GCD的FIFO指的是同一个线程），4肯定晚于1执行（FIFO原则）。因为1、2、3、5（5是并发队列）是在三个不同的串行队列中然后异步加入队列，4和1是加入到同一个一个串行中，所以必然等到1执行完成后再执行
    
    /*
   在MRC和ARC的iOS6之前（这两种情况现在非常少，我是没见过适配iOS6之前的）我们要对GCD进行内存管理，使用下面的方法。
    
    dispatch_release(OneserialDispatchQueue);
    dispatch_retain(OneserialDispatchQueue);
     
     */
    
    // iOS6之后GCD已经进入ARC的管理了，我们就不用管这个了
}

- (void)mainAndGlobalDispatchQueue{
    // 工作中我们大多数情况下不用自己创建Dispatch Queue，我们可以方便的获取系统标准提供的Dispatch Queue那就是下面的两个
   dispatch_queue_t main = dispatch_get_main_queue();// 如其名指的就是主线程（更新UI必须在此线程）所以也肯定是 Serial Dispatch Queue 它的处理在主线程的RunLoop中执行
    
    /*dispatch_get_global_queue是 concurrent Dispatch Queue
     第一个参数有四个优先级
     
     #define DISPATCH_QUEUE_PRIORITY_HIGH 2
     #define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
     #define DISPATCH_QUEUE_PRIORITY_LOW (-2)
     #define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
     
     再向Global Dispatch Queue 中追加处理时，应选择与处理内容对应的优先级，但是XNU内核用于Global Dispatch Queue的线程并不能保证实时性，只是大致判断
     */
    dispatch_queue_t global = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); // dispatch_queue_create创建的就是DISPATCH_QUEUE_PRIORITY_DEFAULT这种优先级
    
}

- (void)setTargetQueue{
    
    dispatch_queue_t serialDispatchQueue = dispatch_queue_create(NULL, NULL);
    dispatch_queue_t globalDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    /*
     变更生成的Dispatch Queue的执行优先级
     第一个参数：要变更的Dispatch Queue
     第二个参数；目标Dispatch Queue
     */
    dispatch_set_target_queue(serialDispatchQueue, globalDispatchQueue);
}


- (void)dispatchAfter{
    int time = 1;
    // 作用：在指定时间后执行处理
    // 注意：dispatch_after并不是在指定时间后执行处理，而只是在指定时间追加处理到Dispatch Queue，如果在每隔1/60秒执行的RunLoop中，可能会在time+1/60秒后执行甚至更久。
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"dispatch_after执行");
    });
}

- (void)dispatchGroup{
    //
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // 1创建dispatch_group_t
    dispatch_group_t group = dispatch_group_create();
    /* 第一个参数：dispatch_group_t
     第二个参数：要执行的block的Dispatch Queue 加入group的线程可以是任意的，主线程子线程都可以，
    */
    dispatch_group_async(group, queue, ^{
        NSLog(@"任务1");
    });
    dispatch_group_async(group, queue, ^{
        sleep(1);
        NSLog(@"任务2");
    });
    dispatch_group_async(group, queue, ^{
        sleep(2);
        NSLog(@"任务3");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"任务4");
    });
    // 3，在所有加到group的任务执行完成后，再执行此任务，无论上边的queue是否一致，还是上边的Queue和dispatch_group_notify中的Queue是否一致，下边的block总是在上边的执行完成后才执行
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"最后任务");
    });
    NSLog(@"dispatch_group_notify是异步执行");
    // 还有一种用法是将dispatch_group_notify换成dispatch_group_wait,但是dispatch_group_wait会堵塞当前线程，直到等待时间到达或者group执行完成
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    // 这个函数是有返回值的
    
    
#warning 最好不要轻易使用dispatch_group_wait，因为会阻塞线程，而且代码也会复杂
   long result = dispatch_group_wait(group, time);
    if (result == 0) {
        NSLog(@"group中的全部处理完成");
        
    }else{
         NSLog(@"group中还有处理在进行");
        
    }
    NSLog(@"dispatch_group_wait阻塞了当前线程");
   
}

- (void)dispatchBarrierAsync{
    //dispatch_barrier_async函数会等待追加到Concurrent Dispatch Queue（串行对于此函数是没有意义的） 上的并行执行的处理全部结束之后，再执行dispatch_barrier_async中的block，此block执行完成后，Concurrent Dispatch Queue的处理又开始并行执行
    // 此函数在处理数据竞争时是非常有用的，比如读数据时不能写数据，写数据时不能读，读数据可以一块执行
    
    //dispatch_barrier_async只能和dispatch_queue_create创建的Queue一起使用，和dispatch_get_global_queue创建的函数一块使用是有问题的
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        sleep(2);
        NSLog(@"读数据1");
    });
    dispatch_async(queue, ^{
        sleep(1);
        NSLog(@"读数据2");
    });
    dispatch_async(queue, ^{
        sleep(3);
        NSLog(@"读数据3");
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"写数据dispatch_barrier_async任务");
    });
    
    dispatch_async(queue, ^{
        sleep(2);
        NSLog(@"读数据4");
    });
    dispatch_async(queue, ^{
        sleep(1);
        NSLog(@"读数据5");
    });
}

- (void)dispatchSync{
    // 如其名，就是同步，就是等待当程处理结束时才执行
    // 我们在主线程需要更新UI，但是在数据没有处理完时不能更新，处理完时要立即更新，所以可以使用此种写法
    NSLog(@"开始");

    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          sleep(1);
        NSLog(@"处理");
    });

    NSLog(@"完结");
#warning dispatch_sync使用时要格外注意，因为很容易造成死锁
    //dispatch_sync,在指定处理没有完成时是不会返回的，下面这种就会造成死锁，原因是主线程在等待block的执行，而无法去执行block
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"死锁");
    });
    NSLog(@"永远不会执行");
    
}















































































































































































@end

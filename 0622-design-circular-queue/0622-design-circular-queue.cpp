class MyCircularQueue {
public:
    int *a;
    int k,s=0;
    int front=-1,rare=-1;
    MyCircularQueue(int k) {
        a=new int[k];
        this->k=k;
    }
    
    bool enQueue(int value) {
        if(isFull())return false;
        if(front ==-1 && rare==-1){
            front=rare=0;
        }
        else{rare = (rare + 1) % k;}
        a[rare] = value;
        s++;
        return true;
    }
    
    bool deQueue() {
        if(isEmpty())return false;
        if(front==rare){
            front=rare=-1;
        }
        else{front=(front+1)%k;}
        s--;
        return true;
    }
    
    int Front() {
        if(s==0)return -1;
        return a[front];
    }
    
    int Rear() {
        if(s==0)return -1;
        return a[rare];
    }
    
    bool isEmpty() {
        return s==0;
    }
    
    bool isFull() {
        return s==k;
    }
};

/**
 * Your MyCircularQueue object will be instantiated and called as such:
 * MyCircularQueue* obj = new MyCircularQueue(k);
 * bool param_1 = obj->enQueue(value);
 * bool param_2 = obj->deQueue();
 * int param_3 = obj->Front();
 * int param_4 = obj->Rear();
 * bool param_5 = obj->isEmpty();
 * bool param_6 = obj->isFull();
 */
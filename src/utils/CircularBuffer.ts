import Deque from 'double-ended-queue'

export class QueueBuffer {
  deque: Deque<string>
  maxSize: number

  constructor(maxSize: number) {
    this.maxSize = maxSize
    this.deque = new Deque()
  }

  public push = (str: string) => {
    for (let i = 0; i < str.length; i += 1) {
      this.addChar(str.charAt(i))
    }
  }

  public getString = () => {
    return this.deque.toArray().join('')
  }

  public getSize = () => {
    return this.deque.length
  }

  private addChar(char: string) {
    if (this.deque.length === this.maxSize) this.deque.shift()
    this.deque.push(char)
  }
}
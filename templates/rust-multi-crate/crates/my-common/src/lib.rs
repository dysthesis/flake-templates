use std::{borrow::Cow, future::Future};
use tokio::sync::mpsc;

/// Naïve recursive Fibonacci for demonstration and property testing.
#[inline]
#[must_use]
pub fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        n => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

/// Echoes messages back with the given prefix.
pub fn echo_task(
    buffer: usize,
    prefix: Cow<'static, str>,
) -> (
    mpsc::Sender<Cow<'static, str>>,
    mpsc::Receiver<String>,
    impl Future<Output = ()>,
) {
    let (in_tx, mut in_rx) = mpsc::channel(buffer);
    let (out_tx, out_rx) = mpsc::channel(buffer);

    (in_tx, out_rx, async move {
        while let Some(msg) = in_rx.recv().await {
            let msg = format!("{prefix} {msg}");
            if out_tx.send(msg).await.is_err() {
                break;
            }
        }
    })
}

#[cfg(test)]
mod test {
    use super::{echo_task, fibonacci};

    #[tokio::test]
    async fn smoke() {
        let (tx, mut rx, fut) = echo_task(10, "hello".into());

        tokio::spawn(fut);

        tx.send("world".into()).await.unwrap();
        assert_eq!("hello world", rx.recv().await.unwrap());

        tx.send("someone".into()).await.unwrap();
        assert_eq!("hello someone", rx.recv().await.unwrap());
    }

    #[tokio::test]
    async fn echo_handles_empty_strings() {
        let (tx, mut rx, fut) = echo_task(1, "".into());
        tokio::spawn(fut);
        tx.send("".into()).await.unwrap();
        assert_eq!(" ", rx.recv().await.unwrap());
    }

    #[test]
    fn base_cases_are_one() {
        assert_eq!(fibonacci(0), 1);
        assert_eq!(fibonacci(1), 1);
    }

    #[test]
    fn recurrence_small_inputs() {
        for n in 0..10 {
            assert_eq!(fibonacci(n + 2), fibonacci(n + 1) + fibonacci(n));
        }
    }

    mod prop {
        use super::fibonacci;
        use proptest::prelude::*;

        proptest! {
            #[test]
            fn recurrence_holds(n in 0u64..21) {
                prop_assert_eq!(fibonacci(n + 2), fibonacci(n + 1) + fibonacci(n));
            }
        }
    }
}

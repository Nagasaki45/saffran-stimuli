DATA_FILE = 'annotated_exp_data.csv'

# Load the data from file
raw.data <- read.csv(DATA_FILE)
participants <- read.csv("participants.csv")

cat("\nParticipants age and gender\n")
cat(sprintf("\nMean age: %f\tStd: %f\n", mean(participants$age), sqrt(var(participants$age))))
print (
  aggregate(
    age ~ gender,
    participants,
    FUN=function(x) (c(mean=mean(x), count=length(x)))
  )
)

cat("\nNumber of participants for each language and test combination\n")
print (
  aggregate(
    participant ~ language + test,
    raw.data,
    FUN=function(x) (length(unique(x)))
  )
)

cat("\nGroup by participant with calculated score\n")
df <- aggregate(
  raw.data$correct, 
  list(language=raw.data$language, test=raw.data$test, participant=raw.data$participant), 
  FUN=function(x) (mean(x) * 36)
)
names(df)[names(df)=="x"] <- "correct"
print (df)

cat("\nGroup by participant with calculated score for each word\n")
df2 <- aggregate(
  raw.data$correct, 
  list(word=raw.data$correct_word, transitional_probability = raw.data$correct_word_trans_prob, language=raw.data$language, participant=raw.data$participant), 
  FUN=function(x) (mean(x) * 6)
)
names(df2)[names(df2)=="x"] <- "correct"
print (df2)

cat("\n1. Stripchart for participant scores\n")
stripchart(df$correct, method = "stack", vertical = TRUE,
           main = "Number of correct answers for each participant", ylab = "Score",
           ylim = c(0, 36), offset = .5, pch = 16) 
abline(h=18, lty= 2)

cat("\n2. Are the results similar for Test 1 and Test 2, for each language?\n")
t.test(correct ~ test, df, subset=(df$language == 1))
cat("\nIf p >= .05, no difference between Test 1 and Test 2 data in Language 1, as expected.\n")
t.test(correct ~ test, df, subset=(df$language == 2))
cat("\nIf p >= .05, no difference between Test 1 and Test 2 data in Language 2, as expected.\n")

cat("\n3. Did people perform better than chance on Language 1?\n")
t.test(df$correct[df$language == 1], mu=18)
cat("\nIf p < .05, people performed better than chance\n")

cat("\n4. Did people perform better than chance on Language 2?\n")
t.test(df$correct[df$language == 2], mu=18)
cat("\nIf p < .05, people performed better than chance\n")

cat("\n5. Are scores on individual words better than chance?\n")
words <- aggregate(
  df2$correct,
  list(word=df2$word, transitional.probability=df2$transitional_probability, language=df2$language),
  FUN=function(x) (c(t.test=t.test(x, mu=3)$p.value, score=mean(x)))
)
names(words)[names(words)=="x"] <- "correct"
words$better.than.chance <- apply(words[,c('correct')], 1, function(x) (x['t.test'] < 0.05))
words
cat("\nNote: In original study, all scores except ADB were better than chance\n")

cat("\n6. Are the results similar for Language 1 and Language 2?\n")
t.test(correct ~ language, df)
cat("\nIf p >= .05, no difference between Language 1 and Language 2 data, as expected.\n")

cat("\n7. ANOVA for words with high vs. low transitional probabilities\n")
cat("\n7.a. First, add a column to the data frame to separate high vs. low probability\n")
df2$high.vs.low <- apply(df2, 1, function(x) (if (x['transitional_probability'] < 0.7) x = 0 else x = 1))
df2
cat("\n7.b. Repeated measures ANOVA for Language 1\n")
anova1 <- aov(correct ~ high.vs.low + Error(participant/high.vs.low), df2, subset=(words$language == 1))
summary(anova1)
cat("\n7.c. Repeated measures ANOVA for Language 2\n")
anova2 <- aov(correct ~ high.vs.low + Error(participant/high.vs.low), df2, subset=(words$language == 2))
summary(anova2)
cat("\nIf p < .05, people were better on words with higher transitional probabilities\n")

cat("\n8. But really, an ANOVA shouldn't have been used. A paired t-test is better\n")
cat("\n8.a. Language 1\n")
t.test(correct ~ high.vs.low, df2, paired = TRUE, subset=(words$language == 1))
cat("\n8.b. Language 2\n")
t.test(correct ~ high.vs.low, df2, paired = TRUE, subset=(words$language == 2))
cat("\nIf p < .05, people were better on words with higher transitional probabilities\n")

cat("\n9. Scatter plot for transitional probability vs. average score for each word\n")
plot(words$transitional.probability, words$correct[,c('score')],
     main="Individual words",
     xlab="Average transitional probability", ylab="Number of correct answers",
     xlim=c(0, 1), ylim=c(0, 6))
abline(lm(words$correct[,c('score')] ~ words$transitional.probability), lty = 2)

cat("\n10. How do results compare with Saffran's linguistics study?\n")
t.test(df$correct, mu=27.2)
cat("\nIf p >= .05, results are similar to linguistics study.\n")

cat("\n11. Decrease in performance during the test. See plots.\n")
trials.correctness <- aggregate(
  correct ~ trial,
  raw.data,
  FUN=mean
)

plot(trials.correctness$trial, trials.correctness$correct,
     main="Trial number effect on correct answers",
     xlab="Trial number", ylab="Average correctness probability",
     ylim=c(0, 1))
abline(lm(trials.correctness$correct ~ trials.correctness$trial), lty = 2)

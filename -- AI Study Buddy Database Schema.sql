-- AI Study Buddy Database Schema
-- Supports user management, document processing, flashcards, quizzes, and learning analytics

-- =====================================================
-- USERS AND AUTHENTICATION
-- =====================================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'premium')),
    storage_used_mb INTEGER DEFAULT 0,
    storage_limit_mb INTEGER DEFAULT 100
);

CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- STUDY MATERIALS
-- =====================================================

CREATE TABLE study_materials (
    material_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT,
    file_type VARCHAR(50),
    page_count INTEGER,
    word_count INTEGER,
    upload_status VARCHAR(20) DEFAULT 'pending' CHECK (upload_status IN ('pending', 'processing', 'completed', 'failed')),
    processing_error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT FALSE
);

CREATE TABLE material_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    color_hex VARCHAR(7),
    icon VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, name)
);

CREATE TABLE material_category_mapping (
    material_id UUID NOT NULL REFERENCES study_materials(material_id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES material_categories(category_id) ON DELETE CASCADE,
    PRIMARY KEY (material_id, category_id)
);

-- =====================================================
-- FLASHCARDS
-- =====================================================

CREATE TABLE flashcard_decks (
    deck_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    material_id UUID REFERENCES study_materials(material_id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    total_cards INTEGER DEFAULT 0,
    mastery_percentage DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_studied TIMESTAMP,
    study_count INTEGER DEFAULT 0
);

CREATE TABLE flashcards (
    card_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES flashcard_decks(deck_id) ON DELETE CASCADE,
    front_content TEXT NOT NULL,
    back_content TEXT NOT NULL,
    front_image_url TEXT,
    back_image_url TEXT,
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    card_type VARCHAR(20) DEFAULT 'basic' CHECK (card_type IN ('basic', 'cloze', 'image', 'reverse')),
    source_page INTEGER,
    source_section TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    position INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE flashcard_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    card_id UUID NOT NULL REFERENCES flashcards(card_id) ON DELETE CASCADE,
    ease_factor DECIMAL(3,2) DEFAULT 2.5,
    interval_days INTEGER DEFAULT 0,
    repetition_count INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP,
    next_review_date DATE,
    total_reviews INTEGER DEFAULT 0,
    correct_reviews INTEGER DEFAULT 0,
    incorrect_reviews INTEGER DEFAULT 0,
    average_response_time_seconds DECIMAL(10,2),
    is_suspended BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, card_id)
);

-- =====================================================
-- QUIZZES
-- =====================================================

CREATE TABLE quizzes (
    quiz_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    material_id UUID REFERENCES study_materials(material_id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    question_count INTEGER NOT NULL,
    time_limit_minutes INTEGER,
    passing_score_percentage INTEGER DEFAULT 70,
    difficulty_level VARCHAR(20) DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'adaptive')),
    is_public BOOLEAN DEFAULT FALSE,
    quiz_type VARCHAR(20) DEFAULT 'practice' CHECK (quiz_type IN ('practice', 'test', 'review')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE quiz_questions (
    question_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID NOT NULL REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer', 'essay')),
    points INTEGER DEFAULT 1,
    explanation TEXT,
    source_page INTEGER,
    source_section TEXT,
    position INTEGER NOT NULL,
    time_limit_seconds INTEGER,
    image_url TEXT
);

CREATE TABLE quiz_answers (
    answer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES quiz_questions(question_id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL DEFAULT FALSE,
    explanation TEXT,
    position INTEGER NOT NULL
);

CREATE TABLE quiz_attempts (
    attempt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    quiz_id UUID NOT NULL REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    score_percentage DECIMAL(5,2),
    points_earned INTEGER,
    points_possible INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    time_spent_seconds INTEGER,
    is_completed BOOLEAN DEFAULT FALSE,
    attempt_number INTEGER DEFAULT 1
);

CREATE TABLE quiz_responses (
    response_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES quiz_attempts(attempt_id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES quiz_questions(question_id) ON DELETE CASCADE,
    selected_answer_id UUID REFERENCES quiz_answers(answer_id),
    text_response TEXT,
    is_correct BOOLEAN,
    points_earned INTEGER DEFAULT 0,
    time_spent_seconds INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MIND MAPS
-- =====================================================

CREATE TABLE mind_maps (
    mindmap_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    material_id UUID REFERENCES study_materials(material_id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    map_data JSONB NOT NULL, -- Stores the entire mind map structure
    thumbnail_url TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP,
    access_count INTEGER DEFAULT 0
);

-- =====================================================
-- CHATBOT INTERACTIONS
-- =====================================================

CREATE TABLE chat_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    material_id UUID REFERENCES study_materials(material_id) ON DELETE SET NULL,
    title VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE chat_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES chat_sessions(session_id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tokens_used INTEGER,
    referenced_page INTEGER,
    referenced_section TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP
);

-- =====================================================
-- STUDY SESSIONS AND ANALYTICS
-- =====================================================

CREATE TABLE study_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    material_id UUID REFERENCES study_materials(material_id) ON DELETE SET NULL,
    session_type VARCHAR(20) NOT NULL CHECK (session_type IN ('reading', 'flashcards', 'quiz', 'mindmap', 'chat')),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    duration_seconds INTEGER,
    pages_viewed INTEGER,
    cards_reviewed INTEGER,
    questions_answered INTEGER,
    correct_answers INTEGER,
    focus_score DECIMAL(5,2), -- 0-100 score based on activity patterns
    notes TEXT
);

CREATE TABLE learning_goals (
    goal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    material_id UUID REFERENCES study_materials(material_id) ON DELETE SET NULL,
    goal_type VARCHAR(20) CHECK (goal_type IN ('daily', 'weekly', 'custom')),
    target_minutes INTEGER,
    target_cards INTEGER,
    target_quizzes INTEGER,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE study_streaks (
    streak_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    current_streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    last_study_date DATE,
    total_study_days INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SPACED REPETITION ALGORITHM
-- =====================================================

CREATE TABLE spaced_repetition_config (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    learning_steps_minutes INTEGER[] DEFAULT ARRAY[1, 10],
    relearning_steps_minutes INTEGER[] DEFAULT ARRAY[10],
    new_cards_per_day INTEGER DEFAULT 20,
    review_cards_per_day INTEGER DEFAULT 200,
    easy_bonus DECIMAL(3,2) DEFAULT 1.3,
    interval_modifier DECIMAL(3,2) DEFAULT 1.0,
    maximum_interval_days INTEGER DEFAULT 36500,
    hard_interval DECIMAL(3,2) DEFAULT 1.2,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- =====================================================
-- SHARING AND COLLABORATION
-- =====================================================

CREATE TABLE shared_materials (
    share_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES study_materials(material_id) ON DELETE CASCADE,
    shared_by_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    shared_with_email VARCHAR(255),
    share_token VARCHAR(255) UNIQUE,
    permission_level VARCHAR(20) DEFAULT 'view' CHECK (permission_level IN ('view', 'comment', 'edit')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    accessed_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP
);

CREATE TABLE material_comments (
    comment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES study_materials(material_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES material_comments(comment_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    page_number INTEGER,
    highlighted_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(token_hash);

CREATE INDEX idx_materials_user_id ON study_materials(user_id);
CREATE INDEX idx_materials_status ON study_materials(upload_status);
CREATE INDEX idx_materials_created ON study_materials(created_at DESC);

CREATE INDEX idx_flashcards_deck_id ON flashcards(deck_id);
CREATE INDEX idx_flashcard_progress_user_card ON flashcard_progress(user_id, card_id);
CREATE INDEX idx_flashcard_progress_next_review ON flashcard_progress(next_review_date);

CREATE INDEX idx_quiz_attempts_user_id ON quiz_attempts(user_id);
CREATE INDEX idx_quiz_attempts_quiz_id ON quiz_attempts(quiz_id);

CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);

CREATE INDEX idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX idx_study_sessions_started ON study_sessions(started_at DESC);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_materials_updated_at BEFORE UPDATE ON study_materials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_decks_updated_at BEFORE UPDATE ON flashcard_decks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flashcards_updated_at BEFORE UPDATE ON flashcards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quizzes_updated_at BEFORE UPDATE ON quizzes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mindmaps_updated_at BEFORE UPDATE ON mind_maps
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SAMPLE QUERIES FOR COMMON OPERATIONS
-- =====================================================

-- Get user's study materials with categories
/*
SELECT 
    sm.*,
    array_agg(mc.name) as categories
FROM study_materials sm
LEFT JOIN material_category_mapping mcm ON sm.material_id = mcm.material_id
LEFT JOIN material_categories mc ON mcm.category_id = mc.category_id
WHERE sm.user_id = $1 AND sm.is_archived = FALSE
GROUP BY sm.material_id
ORDER BY sm.created_at DESC;
*/

-- Get flashcards due for review (spaced repetition)
/*
SELECT 
    f.*,
    fp.ease_factor,
    fp.interval_days,
    fp.next_review_date
FROM flashcards f
JOIN flashcard_progress fp ON f.card_id = fp.card_id
JOIN flashcard_decks fd ON f.deck_id = fd.deck_id
WHERE fp.user_id = $1 
    AND fp.next_review_date <= CURRENT_DATE
    AND fp.is_suspended = FALSE
ORDER BY fp.next_review_date, f.difficulty_level;
*/

-- Get user's learning statistics
/*
SELECT 
    COUNT(DISTINCT DATE(started_at)) as total_study_days,
    SUM(duration_seconds) / 3600.0 as total_hours,
    AVG(focus_score) as avg_focus_score,
    COUNT(DISTINCT material_id) as materials_studied,
    SUM(cards_reviewed) as total_cards_reviewed,
    SUM(questions_answered) as total_questions_answered,
    CASE 
        WHEN SUM(questions_answered) > 0 
        THEN (SUM(correct_answers)::DECIMAL / SUM(questions_answered) * 100)
        ELSE 0 
    END as overall_accuracy
FROM study_sessions
WHERE user_id = $1 
    AND started_at >= CURRENT_DATE - INTERVAL '30 days';
*/

-- Get quiz performance over time
/*
SELECT 
    DATE(completed_at) as date,
    AVG(score_percentage) as avg_score,
    COUNT(*) as quizzes_taken
FROM quiz_attempts
WHERE user_id = $1 
    AND is_completed = TRUE
    AND completed_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(completed_at)
ORDER BY date;
*/

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

/*
-- Insert sample user
INSERT INTO users (email, username, password_hash, first_name, last_name)
VALUES ('test@example.com', 'testuser', '$2b$10$xxxxxxxxxxx', 'Test', 'User');

-- Insert sample study material
INSERT INTO study_materials (user_id, title, description, file_url, file_name, file_type, upload_status)
VALUES (
    (SELECT user_id FROM users WHERE email = 'test@example.com'),
    'Introduction to Machine Learning',
    'Comprehensive guide to ML fundamentals',
    '/uploads/ml-guide.pdf',
    'ml-guide.pdf',
    'application/pdf',
    'completed'
);

-- Insert sample flashcard deck
INSERT INTO flashcard_decks (user_id, material_id, title, description)
VALUES (
    (SELECT user_id FROM users WHERE email = 'test@example.com'),
    (SELECT material_id FROM study_materials LIMIT 1),
    'ML Fundamentals',
    'Key concepts from the ML guide'
);
*/